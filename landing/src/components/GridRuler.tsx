"use client";

import { motion } from "framer-motion";

export function GridRuler() {
    return (
        <div className="absolute inset-0 pointer-events-none select-none z-0 overflow-hidden">
            <div
                className="absolute inset-0 z-0 opacity-[0.12]"
                style={{
                    backgroundImage: `
                        linear-gradient(to right, #808080 1px, transparent 1px),
                        linear-gradient(to bottom, #808080 1px, transparent 1px)
                    `,
                    backgroundSize: "14rem 14rem",
                    maskImage: "radial-gradient(ellipse at center, black 40%, transparent 80%)"
                }}
            />

            <div
                className="absolute inset-0 z-0 opacity-[0.07]"
                style={{
                    backgroundImage: `
                        linear-gradient(to right, #808080 1px, transparent 1px),
                        linear-gradient(to bottom, #808080 1px, transparent 1px)
                    `,
                    backgroundSize: "3.5rem 3.5rem",
                    maskImage: "radial-gradient(ellipse at center, black 40%, transparent 80%)"
                }}
            />

            <div className="absolute inset-0 z-0">
                <Crosshair style={{ top: "33%", left: "20%" }} delay={0} />
                <Crosshair style={{ top: "33%", right: "20%" }} delay={0.2} />
                <Crosshair style={{ bottom: "33%", left: "20%" }} delay={0.4} />
                <Crosshair style={{ bottom: "33%", right: "20%" }} delay={0.6} />

                <Crosshair style={{ top: "15%", left: "50%" }} delay={0.8} />
            </div>

            <div className="absolute top-0 left-0 right-0 h-32 bg-gradient-to-b from-black to-transparent z-10" />

            <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-black to-transparent z-10" />
        </div>
    );
}

function Crosshair({ style, delay }: { style: React.CSSProperties, delay: number }) {
    return (
        <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay, duration: 1 }}
            className="absolute w-6 h-6 -translate-x-1/2 -translate-y-1/2 flex items-center justify-center opacity-30"
            style={style}
        >
            <div className="absolute w-full h-[1px] bg-zinc-700" />
            <div className="absolute h-full w-[1px] bg-zinc-700" />
        </motion.div>
    );
}
