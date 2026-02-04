import React from 'react';

export const CornerBrackets = () => (
    <>
        <div className="corner-bracket corner-tl"></div>
        <div className="corner-bracket corner-tr"></div>
        <div className="corner-bracket corner-bl"></div>
        <div className="corner-bracket corner-br"></div>
    </>
);

export const GlowBorders = ({ h = true, v = false }) => (
    <div className="absolute inset-0 pointer-events-none overflow-hidden">
        {h && <div className="glow-border-h top-0 opacity-40"></div>}
        {h && <div className="glow-border-h bottom-0 opacity-40"></div>}
        {v && <div className="glow-border-v left-0 opacity-40"></div>}
        {v && <div className="glow-border-v right-0 opacity-40"></div>}
    </div>
);
