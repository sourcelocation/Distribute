"use client";

import { motion, useTime, useTransform } from "framer-motion";
import Image from "next/image";

const v0 = 0.1; // Start speed (deg/ms)
const v1 = 0.0288; // Target speed (deg/ms)
const T = 2000; // Duration (ms)

function SpinningDisk() {
    const time = useTime();
    const rotate = useTransform(time, (t) => {
        if (t < T) {
            return v0 * t - (v0 - v1) * (t * t / (2 * T));
        } else {
            const xT = (v0 + v1) * T / 2;
            return xT + v1 * (t - T);
        }
    });

    return (
        <motion.div
            style={{
                transformStyle: "preserve-3d",
                rotate,
                willChange: "transform",
                backfaceVisibility: "hidden",
            }}
            className="relative w-full h-full"
        >
            <Image
                src="/vinyl-spinning-opt.png"
                alt="Vinyl"
                fill
                quality={90}
                className="object-contain"
                priority
                sizes="(max-width: 768px) 100vw, 600px"
                style={{ transform: "translateZ(0)" }}
            />


        </motion.div>
    );
}

export function VinylAnimation() {
    return (
        <div className="pointer-events-none absolute inset-0 flex justify-center items-center z-0">
            <motion.div
                initial={{
                    y: "80vh",
                    opacity: 0,
                    rotateX: 0,
                    scale: 3.0,
                    filter: "brightness(1)",
                }}
                animate={{
                    y: "-10vh",
                    opacity: 1,
                    rotateX: 75,
                    scale: 2.5,
                    z: -200,
                    filter: "brightness(0.25)",
                }}
                transition={{
                    duration: 6.0,
                    ease: [0.16, 1, 0.3, 1],
                    opacity: { duration: 1.5, ease: "easeOut" }
                }}
                style={{
                    perspective: "1200px",
                    transformStyle: "preserve-3d",
                }}
                className="relative w-[600px] h-[600px] flex items-center justify-center"
            >
                <div className="relative w-full h-full" style={{ transformStyle: "preserve-3d", backfaceVisibility: "hidden" }}>
                    <SpinningDisk />

                    {/* Consolidated Overlay: Fades + Lighting in one layer */}
                    <div
                        className="absolute inset-0 scale-105 pointer-events-none"
                        style={{
                            background: `
                                linear-gradient(to bottom, black 0%, transparent 40%, transparent 60%, rgba(0,0,0,0.5) 100%),
                                radial-gradient(circle at 50% 0%, rgba(255,255,255,0.08) 0%, transparent 60%)
                            `,
                            transform: "translateZ(1px)",
                            borderRadius: "50%",
                            backfaceVisibility: "hidden"
                        }}
                    />
                </div>
            </motion.div>
        </div>
    );
}
