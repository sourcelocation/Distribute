import { motion, useScroll, useTransform, useSpring, useAnimation, useMotionValueEvent } from "framer-motion";
import Image from "next/image";
import { useRef } from "react";

export function PiracyDisclaimer() {
    const containerRef = useRef<HTMLDivElement>(null);
    const { scrollYProgress } = useScroll({
        target: containerRef,
        offset: ["start end", "end start"],
    });

    const cutProgress = useTransform(scrollYProgress, [0.3, 0.45], [0, 1]);

    const separation = useTransform(scrollYProgress, [0.45, 0.7], [0, 40]);
    const rotationTop = useTransform(scrollYProgress, [0.45, 0.7], [0, -5]);
    const rotationBottom = useTransform(scrollYProgress, [0.45, 0.7], [0, 5]);
    const xTop = useTransform(scrollYProgress, [0.45, 0.7], [0, -20]);
    const xBottom = useTransform(scrollYProgress, [0.45, 0.7], [0, 15]);

    const opacity = useTransform(scrollYProgress, [0.1, 0.3], [0, 1]);
    const scale = useTransform(scrollYProgress, [0.1, 0.3], [0.8, 1]);

    const flashControls = useAnimation();
    const screenFlashControls = useAnimation();
    const shakeControls = useAnimation();
    const lastProgress = useRef(0);

    useMotionValueEvent(scrollYProgress, "change", (latest) => {
        if (lastProgress.current < 0.45 && latest >= 0.45) {
            flashControls.start({
                opacity: [0, 1, 0],
                transition: { duration: 0.2, times: [0, 0.1, 1] }
            });
            screenFlashControls.start({
                opacity: [0, 0.2, 0],
                transition: { duration: 0.15, times: [0, 0.1, 1] }
            });
            shakeControls.start({
                x: [0, -5, 5, -3, 3, 0],
                y: [0, 5, -5, 3, -3, 0],
                transition: { duration: 0.3 }
            });
        }

        lastProgress.current = latest;
    });

    return (
        <section ref={containerRef} className="relative z-10 min-h-[150vh] flex flex-col items-center justify-start overflow-visible pt-40 pb-40">
            <div className="sticky top-1/4 flex flex-col items-center justify-center gap-12 w-full">

                <motion.div
                    style={{ opacity, scale }}
                    className="text-center z-20 space-y-4"
                >
                    <h2 className="text-4xl md:text-6xl font-bold tracking-tight text-white drop-shadow-2xl">
                        Leave the high seas behind.
                    </h2>
                    <p className="text-zinc-400 text-lg md:text-xl max-w-xl mx-auto leading-relaxed">
                        Distribute is built for your owned library. Support the artists you love by purchasing their music.
                    </p>
                </motion.div>

                <motion.div
                    animate={shakeControls}
                    className="relative w-[300px] md:w-[400px] [perspective:1000px] flex flex-col"
                >

                    <motion.div
                        style={{
                            y: useTransform(separation, (val) => -val),
                            x: xTop,
                            rotateZ: rotationTop,
                            originX: 0.5,
                            originY: 1
                        }}
                        className="relative z-10 w-full"
                    >
                        <Image
                            src="/top-flag.png"
                            alt="Pirate Flag Top"
                            width={0}
                            height={0}
                            sizes="(max-width: 768px) 300px, 400px"
                            quality={90}
                            className="w-full h-auto block"
                            priority
                        />
                    </motion.div>

                    <motion.div
                        style={{
                            y: separation,
                            x: xBottom,
                            rotateZ: rotationBottom,
                            originX: 0.5,
                            originY: 0
                        }}
                        className="relative z-10 w-full"
                    >
                        <Image
                            src="/bottom-flag.png"
                            alt="Pirate Flag Bottom"
                            width={0}
                            height={0}
                            sizes="(max-width: 768px) 300px, 400px"
                            quality={90}
                            className="w-full h-auto block"
                            priority
                        />
                    </motion.div>

                    <motion.div
                        style={{
                            scaleX: cutProgress,
                            opacity: useTransform(cutProgress, [0, 0.5, 1], [0, 1, 0]),
                            top: "50%"
                        }}
                        className="absolute left-0 w-full h-[2px] bg-white shadow-[0_0_20px_rgba(255,255,255,0.8)] z-30 origin-left -translate-y-1/2"
                    />

                    <motion.div
                        animate={flashControls}
                        initial={{ opacity: 0 }}
                        className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[150%] h-[150%] bg-white blur-[80px] z-20 rounded-full pointer-events-none mix-blend-overlay"
                    />

                </motion.div>
            </div>

            <motion.div
                animate={screenFlashControls}
                initial={{ opacity: 0 }}
                className="fixed inset-0 bg-white z-[100] pointer-events-none mix-blend-overlay"
            />
        </section>
    );
}