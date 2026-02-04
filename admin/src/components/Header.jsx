import React, { useEffect, useState } from 'react';
import { Cpu, Clock } from 'lucide-react';
import { useStats } from '../StatsContext';

const formatUptime = (seconds) => {
    if (!seconds) return "00:00:00";
    const d = Math.floor(seconds / (3600 * 24));
    const h = Math.floor((seconds % (3600 * 24)) / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;

    // Format: DD:HH:MM:SS
    return `${d.toString().padStart(2, '0')}:${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
};

const Header = () => {
    const { stats } = useStats();
    const [liveUptime, setLiveUptime] = useState(0);

    useEffect(() => {
        if (stats?.uptime) {
            // If the difference is huge, sync it, otherwise let local ticker handle it smoother
            if (Math.abs(stats.uptime - liveUptime) > 5) {
                setLiveUptime(stats.uptime);
            }
        }
    }, [stats]);

    useEffect(() => {
        const timer = setInterval(() => setLiveUptime(prev => prev + 1), 1000);
        return () => clearInterval(timer);
    }, []);

    return (
        <header className="bg-panel-dark/80 backdrop-blur-xl border-b border-white/5 p-3 flex justify-between items-center z-40 sticky top-0 relative">
            <div className="glow-border-h bottom-0 left-1/2 -translate-x-1/2 w-full opacity-20"></div>
            <div className="flex items-center gap-2">
                <img src="/logo.png" alt="Logo" className="w-10 h-10 p-2" />
                <div className="flex flex-col">
                    <span className="text-[10px] leading-tight text-white/50">ADMIN</span>
                    <span className="text-primary font-bold">DISTRIBUTOR</span>
                </div>
            </div>
            <div className="flex items-center gap-6">
                <div className="flex items-center gap-3 bg-white/5 p-2 px-3 border border-white/5 relative">
                    <div className="glow-border-v left-0 h-1/2 opacity-30"></div>
                    <Cpu className="w-3 h-3 text-primary/50" />
                    <div className="flex flex-col text-right">
                        <span className="text-[10px] leading-tight text-white/50">CPU USAGE</span>
                        <span className="text-white font-bold">
                            {stats?.cpu ? `${stats.cpu.toFixed(1)}%` : '...'}
                        </span>
                    </div>
                </div>
                <div className="flex items-center gap-3 bg-white/5 p-2 px-3 border border-white/5 relative">
                    <div className="glow-border-v left-0 h-1/2 opacity-30"></div>
                    <Clock className="w-3 h-3 text-primary/50" />
                    <div className="flex flex-col text-right">
                        <span className="text-[10px] leading-tight text-white/50">UPTIME</span>
                        <span className="text-white font-bold font-mono">
                            {formatUptime(liveUptime)}
                        </span>
                    </div>
                </div>
            </div>
        </header>
    );
};

export default Header;
