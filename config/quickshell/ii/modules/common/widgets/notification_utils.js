
/**
 * @param { string } summary 
 * @returns { string }
 */
function findSuitableMaterialSymbol(summary = "") {
    const defaultType = 'chat';
    if(summary.length === 0) return defaultType;

    const keywordsToTypes = {
        'reboot': 'restart_alt',
        'record': 'screen_record',
        'battery': 'power',
        'power': 'power',
        'screenshot': 'screenshot_monitor',
        'welcome': 'waving_hand',
        'time': 'schedule',
        'installed': 'download',
        'configuration reloaded': 'reset_wrench',
        'unable': 'question_mark',
        "couldn't": 'question_mark',
        'config': 'reset_wrench',
        'update': 'update',
        'ai response': 'neurology',
        'control': 'settings',
        'upsca': 'compare',
        'music': 'queue_music',
        'install': 'deployed_code_update',
        'input': 'keyboard_alt',
        'preedit': 'keyboard_alt',
        'kde connect': 'phone_android',
        'kdeconnect': 'phone_android',
        'startswith:file': 'folder_copy', // Declarative startsWith check
    };

    const lowerSummary = summary.toLowerCase();

    for (const [keyword, type] of Object.entries(keywordsToTypes)) {
        if (keyword.startsWith('startswith:')) {
            const startsWithKeyword = keyword.replace('startswith:', '');
            if (lowerSummary.startsWith(startsWithKeyword)) {
                return type;
            }
        } else if (lowerSummary.includes(keyword)) {
            return type;
        }
    }

    return defaultType;
}

/**
 * @param { number | string | Date } timestamp 
 * @returns { string }
 */
const getFriendlyNotifTimeString = (timestamp) => {
    if (!timestamp) return '';
    const messageTime = new Date(timestamp);
    const now = new Date();
    const diffMs = now.getTime() - messageTime.getTime();

    // Less than 1 minute
    if (diffMs < 60000) 
        return 'Now';
    
    // Same day - show relative time
    if (messageTime.toDateString() === now.toDateString()) {
        const diffMinutes = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        
        if (diffHours > 0) {
            return `${diffHours}h`;
        } else {
            return `${diffMinutes}m`;
        }
    }
    
    // Yesterday
    if (messageTime.toDateString() === new Date(now.getTime() - 86400000).toDateString()) 
        return 'Yesterday';
    
    // Older dates
    return Qt.formatDateTime(messageTime, "MMMM dd");
};

/**
 * Check if text contains markdown-style syntax (so we can render as rich text when needed).
 * @param { string } text
 * @returns { boolean }
 */
function hasMarkdown(text) {
    if (!text || typeof text !== 'string') return false;
    return /\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`|\[[^\]]+\]\([^)]+\)/.test(text);
}

/**
 * Convert simple markdown to Qt StyledText/HTML for notification body.
 * Handles: **bold**, *italic*, `code`, [label](url), newlines.
 * Only converts when patterns are present; plain text is returned with just \n -> <br/>.
 * @param { string } text
 * @returns { string }
 */
function markdownToHtml(text) {
    if (!text || typeof text !== 'string') return '';
    let out = text;
    // Links first (so brackets/parens aren't used by other patterns)
    out = out.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
    // Bold **...**
    out = out.replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>');
    // Italic *...* (do after bold so ** is already replaced)
    out = out.replace(/\*([^*]+)\*/g, '<i>$1</i>');
    // Inline code `...`
    out = out.replace(/`([^`]+)`/g, '<code style="background:rgba(128,128,128,0.2);padding:1px 4px;border-radius:3px;">$1</code>');
    // Newlines
    out = out.replace(/\n/g, '<br/>');
    return out;
}