# Fix blurry icons/fonts in Qt/KDE apps (reddit r/kde 1mgij1b)
# Round Qt scale factors to nearest integer, prefer floor at ties (1.5 -> 1)
export QT_SCALE_FACTOR_ROUNDING_POLICY=RoundPreferFloor
