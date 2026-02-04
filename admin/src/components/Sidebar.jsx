import React from 'react';
import { NavLink } from 'react-router-dom';
import { Activity, List, Music, Database, Mic, PlayCircle, Users, ShieldAlert, Settings } from 'lucide-react';
import { useStats } from '../StatsContext';

const Sidebar = () => {
    const { stats } = useStats();

    const groups = [
        {
            title: 'System',
            items: [
                { icon: Activity, label: 'Dashboard', path: '/dashboard' },
            ]
        },
        {
            title: 'Database',
            items: [
                { icon: Music, label: 'Songs', path: '/songs' },
                { icon: Database, label: 'Albums', path: '/albums' },
                { icon: Mic, label: 'Artists', path: '/artists' },
                { icon: PlayCircle, label: 'Playlists', path: '/playlists' }
            ]
        },
        {
            title: 'Management',
            items: [
                { icon: Users, label: 'Users', path: '/users' },
                { icon: Settings, label: 'Settings', path: '/settings' }
            ]
        }
    ];

    return (
        <aside className="w-64 border-r border-white/10 bg-bg-dark/50 flex flex-col p-4 gap-8 overflow-y-auto custom-scrollbar backdrop-blur-sm">
            {groups.map((group, i) => (
                <div key={i} className="flex flex-col gap-2">
                    <div className="text-[10px] text-white/30 tracking-[0.2em] pl-4 mb-2 flex items-center gap-2">
                        <span className="w-1 h-1 bg-primary/30 rounded-full"></span>
                        {group.title.toUpperCase()}
                    </div>
                    {group.items.map((item, j) => (
                        <NavLink
                            key={j}
                            to={item.path}
                            className={({ isActive }) => `sidebar-btn group relative overflow-hidden ${isActive ? 'active border-l-2 border-primary bg-white/5' : 'border-l-2 border-transparent hover:border-white/20'}`}
                        >
                            {({ isActive }) => (
                                <>
                                    <div className={`absolute inset-0 fui-btn-bg opacity-0 transition-opacity duration-300 ${isActive ? 'opacity-100' : 'group-hover:opacity-100'}`}></div>
                                    <item.icon className={`w-4 h-4 z-10 relative transition-colors duration-300 ${isActive ? 'text-primary text-glow' : 'text-slate-400 group-hover:text-white'}`} />
                                    <span className={`font-medium z-10 relative text-xs tracking-wider transition-all duration-300 ${isActive ? 'text-white translate-x-1' : 'text-slate-400 group-hover:text-white group-hover:translate-x-1'}`}>
                                        {item.label}
                                    </span>
                                    {isActive && (
                                        <span className="absolute right-2 w-1.5 h-1.5 bg-primary rounded-full animate-pulse shadow-[0_0_5px_currentColor]"></span>
                                    )}
                                </>
                            )}
                        </NavLink>
                    ))}
                </div>
            ))}
            <div className="flex flex-col gap-2">
                <div className="mt-auto p-4 bg-primary/5 border border-primary/20 space-y-2 relative overflow-hidden group hover:border-primary/40 transition-colors">
                    <div className="flex justify-between items-center text-[10px]">
                        <span className="text-primary/70 font-mono tracking-wider">STORAGE</span>
                        <span className="text-primary animate-pulse font-bold text-[8px]">
                            {stats?.storage ? `${stats.storage.percent}%` : '...'}
                        </span>
                    </div>
                    <div className="h-1 bg-white/5 overflow-hidden">
                        <div
                            className="h-full bg-primary shadow-[0_0_8px_rgba(0,255,194,0.5)] relative overflow-hidden transition-all duration-1000 ease-out"
                            style={{ width: stats?.storage ? `${stats.storage.percent}%` : '0%' }}
                        >
                            <div className="absolute inset-0 bg-white/20 animate-slide-in"></div>
                        </div>
                    </div>
                    {stats?.storage && (
                        <div className="flex justify-between text-[8px] text-white/30 font-mono">
                            <span>{stats.storage.used}</span>
                            <span>{stats.storage.total}</span>
                        </div>
                    )}
                </div>
            </div>
        </aside>
    );
};

export default Sidebar;
