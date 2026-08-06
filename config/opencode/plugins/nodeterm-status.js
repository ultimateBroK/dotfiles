// nodeterm managed plugin — do not edit (reinstalled at app launch)
import fs from 'node:fs'
import http from 'node:http'

export const NodetermStatus = async () => {
  const nodeId = process.env.NODETERM_NODE_ID
  if (!nodeId) return {}
  const live = () => {
    const conf = {
      port: process.env.NODETERM_HOOK_PORT,
      sock: process.env.NODETERM_HOOK_SOCK,
      token: process.env.NODETERM_HOOK_TOKEN,
      version: process.env.NODETERM_HOOK_VERSION
    }
    try {
      const file = process.env.NODETERM_HOOK_ENDPOINT
      if (file) {
        for (const line of fs.readFileSync(file, 'utf8').split('\n')) {
          const m = line.match(/^NODETERM_HOOK_(PORT|SOCK|TOKEN|VERSION)=(.*)$/)
          if (m) conf[m[1].toLowerCase()] = m[2]
        }
      }
    } catch {}
    return conf
  }
  const post = (event, extra) => {
    try {
      const { port, sock, token, version } = live()
      if (!token || (!sock && !port)) return
      const payload = JSON.stringify({ event, ...extra })
      const headers = {
        'content-type': 'application/x-www-form-urlencoded',
        'x-nodeterm-hook-token': token
      }
      const body =
        'nodeId=' + encodeURIComponent(nodeId) +
        '&version=' + encodeURIComponent(version || '') +
        '&payload=' + encodeURIComponent(payload)
      if (sock && typeof Bun !== 'undefined') {
        fetch('http://localhost/hook/opencode', { method: 'POST', unix: sock, headers, body }).catch(() => {})
      } else if (sock) {
        const req = http.request(
          { socketPath: sock, path: '/hook/opencode', method: 'POST', headers },
          (res) => res.resume()
        )
        req.on('error', () => {})
        req.end(body)
      } else {
        fetch('http://127.0.0.1:' + port + '/hook/opencode', { method: 'POST', headers, body }).catch(() => {})
      }
    } catch {}
  }
  const seenUserMsgs = new Set()
  return {
    event: async (input) => {
      const ev = input && input.event
      if (!ev || !ev.type) return
      const p = ev.properties || {}
      const info = p.info || {}
      switch (ev.type) {
        case 'session.created':
          return post('session.created', { sessionID: info.id || p.sessionID })
        case 'session.idle':
        case 'session.error':
          return post(ev.type, { sessionID: p.sessionID })
        case 'permission.updated':
          return post('permission.asked', { sessionID: p.sessionID })
        case 'permission.replied':
          return post('permission.replied', { sessionID: p.sessionID })
        // The question (elicitation) dialog blocks the turn WITHOUT idling the session —
        // unforwarded, the badge sat on RUNNING while the TUI waited for an answer.
        case 'question.asked':
        case 'question.replied':
        case 'question.rejected':
          return post(ev.type, { sessionID: p.sessionID })
        case 'message.updated': {
          if ((info.role || p.role) !== 'user') return
          if (info.id) {
            if (seenUserMsgs.has(info.id)) return
            seenUserMsgs.add(info.id)
            if (seenUserMsgs.size > 500) {
              for (const first of seenUserMsgs) { seenUserMsgs.delete(first); break }
            }
          }
          return post('message.updated', { sessionID: info.sessionID || p.sessionID, role: 'user' })
        }
      }
    },
    'tool.execute.before': async (input) =>
      post('tool.execute.before', { sessionID: input && input.sessionID })
  }
}
