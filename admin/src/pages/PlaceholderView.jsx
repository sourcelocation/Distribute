import React from 'react';
import { CornerBrackets, GlowBorders } from '../components/FUI';
import { ShieldAlert } from 'lucide-react';

const PlaceholderView = ({ title }) => (
    <main className="flex-1 overflow-y-auto grid-bg p-6 flex flex-col items-center justify-center animate-slide-in">
        <div className="panel p-12 text-center border-primary/20 bg-black/40 backdrop-blur-sm max-w-md w-full relative group">
            <CornerBrackets />
            <GlowBorders h={true} v={true} />

            <div className="w-16 h-16 mx-auto mb-6 relative">
                <div className="absolute inset-0 border-2 border-dashed border-primary/30 rounded-full animate-[spin_10s_linear_infinite]"></div>
                <div className="absolute inset-2 border border-primary/50 rounded-full animate-[ping_3s_ease-in-out_infinite]"></div>
                <ShieldAlert className="w-full h-full p-4 text-primary opacity-80" />
            </div>

            <h2 className="text-3xl font-bold text-primary mb-2 tracking-[0.2em] glitch-hover transition-all">{title?.toUpperCase()}</h2>
            <div className="text-xs text-secondary font-mono animate-pulse mb-8">
                [ ENCRYPTED DATA STREAM ]
            </div>

            <div className="font-mono text-[10px] text-slate-500 space-y-2 border-t border-white/5 pt-4">
                <div className="flex justify-between px-8">
                    <span>ACCESS_LEVEL:</span>
                    <span className="text-red-400">RESTRICTED</span>
                </div>
                <div className="flex justify-between px-8">
                    <span>KEY_ID:</span>
                    <span className="text-slate-600">NULL_PTR_EXC</span>
                </div>
                <div className="flex justify-between px-8">
                    <span>LATENCY:</span>
                    <span className="text-slate-600">-- ms</span>
                </div>
            </div>

            <button className="mt-8 px-6 py-2 bg-primary/10 border border-primary/30 text-primary hover:bg-primary hover:text-black transition-all text-xs font-bold tracking-widest uppercase">
                Request Access
            </button>
        </div>
    </main>
);

export default PlaceholderView;
