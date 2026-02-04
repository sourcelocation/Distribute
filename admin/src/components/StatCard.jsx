import React from 'react';

import { Link } from 'react-router-dom';

const StatCard = ({ title, value, sub, subColor = "text-primary", live = false, to }) => {
    const CardContent = (
        <div className="panel p-4 group cursor-pointer hover:border-primary/30 transition-all duration-300 relative h-full">
            <div className="corner-bracket corner-tl group-hover:w-4 group-hover:h-4 transition-all"></div>
            <div className="flex justify-between items-start mb-3">
                <span className="text-[10px] text-white/50 font-bold tracking-wider">{title}</span>
                {live && (
                    <div className="flex items-center gap-1.5 px-2 py-0.5 bg-primary/10 border border-primary/20 rounded-sm">
                        <span className="w-1 h-1 rounded-full bg-primary animate-pulse"></span>
                        <span className="text-[8px] text-primary font-bold">LIVE</span>
                    </div>
                )}
            </div>
            <div className="text-3xl font-bold text-white tracking-tighter mb-1">{value}</div>
            <div className={`text-[10px] font-mono ${subColor} flex items-center gap-1`}>
                {sub}
            </div>
        </div>
    );

    if (to) {
        return <Link to={to} className="block h-full">{CardContent}</Link>;
    }

    return CardContent;
};

export default StatCard;
