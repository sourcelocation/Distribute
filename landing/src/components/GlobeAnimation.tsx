"use client";
import createGlobe from "cobe";
import { useEffect, useRef } from "react";
import { useSpring, useMotionValue } from "framer-motion";

export function GlobeAnimation() {
    const canvasRef = useRef<HTMLCanvasElement>(null);
    const pointerInteracting = useRef(null);
    const pointerInteractionMovement = useRef(0);
    const springR = useSpring(0, {
        mass: 1,
        stiffness: 280,
        damping: 40,
    });

    useEffect(() => {
        let phi = -1.29;
        let width = 0;
        const onResize = () => canvasRef.current && (width = canvasRef.current.offsetWidth)
        window.addEventListener('resize', onResize)
        onResize()
        const globe = createGlobe(canvasRef.current!, {
            devicePixelRatio: 2,
            width: width * 4,
            height: width * 4,
            phi: 0,
            theta: 0.5,
            dark: 1,
            diffuse: 1.2,
            mapSamples: 16000,
            mapBrightness: 6,
            baseColor: [0.3, 0.3, 0.3],
            markerColor: [0.1, 0.8, 0.0],
            glowColor: [0.4, 0.4, 0.4],
            markers: [
            ],
            onRender: (state) => {
                state.phi = phi + springR.get()
                phi += 0.005
                state.width = width * 2
                state.height = width * 2
            }
        })
        setTimeout(() => canvasRef.current!.style.opacity = '1')
        return () => {
            globe.destroy();
            window.removeEventListener('resize', onResize);
        }
    }, [])
    return (
        <div style={{ width: '100%', maxWidth: 600, aspectRatio: 1 }} className="mx-auto grayscale opacity-80 mix-blend-plus-lighter">
            <canvas
                ref={canvasRef}
                style={{
                    width: '100%',
                    height: '100%',
                    contain: 'layout paint size',
                    opacity: 0,
                    transition: 'opacity 1s ease',
                }}
            />
        </div>
    )
}
