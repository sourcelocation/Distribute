"use client";

import React, { useEffect, useRef, useState } from "react";
import Matter from "matter-js";
import Image from "next/image";

interface VinylPhysicsProps {
    titleRef?: React.RefObject<HTMLHeadingElement | null>;
}

export function VinylPhysics({ titleRef }: VinylPhysicsProps) {
    const containerRef = useRef<HTMLDivElement>(null);
    const engineRef = useRef<Matter.Engine | null>(null);
    const [bodies, setBodies] = useState<Matter.Body[]>([]);

    const textureMap = useRef(new Map<number, number>());

    useEffect(() => {
        if (!containerRef.current) return;

        const Engine = Matter.Engine;
        const Runner = Matter.Runner;
        const Bodies = Matter.Bodies;
        const World = Matter.World;

        const engine = Engine.create();
        engineRef.current = engine;

        engine.gravity.y = 0;
        engine.gravity.x = 0;

        const dimensions = {
            width: containerRef.current.clientWidth,
            height: containerRef.current.clientHeight
        };

        const runner = Runner.create();

        const wallOptions = {
            isStatic: true,
            restitution: 0.9,
            friction: 0,
            frictionStatic: 0,
            render: { visible: false }
        };

        const ground = Bodies.rectangle(dimensions.width / 2, dimensions.height + 60, dimensions.width + 200, 120, wallOptions);
        const ceiling = Bodies.rectangle(dimensions.width / 2, -60, dimensions.width + 200, 120, wallOptions);

        let titleBox: Matter.Body | null = null;
        const updateTitleBox = () => {
            if (titleRef?.current && containerRef.current) {
                const titleRect = titleRef.current.getBoundingClientRect();
                const containerRect = containerRef.current.getBoundingClientRect();

                const x = titleRect.left - containerRect.left + titleRect.width / 2;
                const y = titleRect.top - containerRect.top + titleRect.height / 2;
                const width = titleRect.width;
                const height = titleRect.height;

                if (titleBox) {
                    World.remove(engine.world, titleBox);
                }

                titleBox = Bodies.rectangle(x, y, width, height, {
                    ...wallOptions,
                    label: 'title'
                });
                World.add(engine.world, titleBox);
            }
        };

        World.add(engine.world, [ground, ceiling]);
        updateTitleBox();

        Runner.run(runner, engine);

        const mouse = { x: dimensions.width / 2, y: dimensions.height / 2 };

        const onBeforeUpdate = () => {
            const bodies = Matter.Composite.allBodies(engine.world);
            bodies.forEach(body => {
                if (body.isStatic) return;

                const dx = mouse.x - body.position.x;
                const dy = mouse.y - body.position.y;
                const distance = Math.sqrt(dx * dx + dy * dy);

                const targetRadius = 200;
                const radialForceStrength = 0.000002 * body.mass;
                const diff = distance - targetRadius;

                const radialMagnitude = diff * radialForceStrength;

                const tangentStrength = 0.00001 * body.mass;

                let fx = 0;
                let fy = 0;

                if (distance > 0) {
                    const nx = dx / distance;
                    const ny = dy / distance;

                    fx += nx * radialMagnitude;
                    fy += ny * radialMagnitude;

                    fx += -ny * tangentStrength;
                    fy += nx * tangentStrength;
                }

                Matter.Body.applyForce(body, body.position, { x: fx, y: fy });

                const maxSpeed = 10;
                const speed = Matter.Vector.magnitude(body.velocity);
                if (speed > maxSpeed) {
                    const ratio = maxSpeed / speed;
                    Matter.Body.setVelocity(body, {
                        x: body.velocity.x * ratio,
                        y: body.velocity.y * ratio
                    });
                }
            });
        };

        Matter.Events.on(engine, 'beforeUpdate', onBeforeUpdate);

        const vinylRadius = 60;
        const createdBodies: Matter.Body[] = [];
        const rotationData = new Map<number, { speed: number, current: number }>();
        const maxVinyls = 11;
        let spawnedCount = 0;

        const spawnInterval = setInterval(() => {
            if (spawnedCount >= maxVinyls) {
                clearInterval(spawnInterval);
                return;
            }

            const currentW = dimensions.width;
            const currentH = dimensions.height;

            if (currentW === 0 || currentH === 0) return;

            const isLeft = Math.random() > 0.5;
            const startX = isLeft ? -vinylRadius * 1.5 : currentW + vinylRadius * 1.5;
            const startY = Math.random() * (currentH * 0.4) + (currentH * 0.5);

            const collisionRadius = 54;

            const body = Bodies.circle(startX, startY, collisionRadius, {
                restitution: 0.8,
                friction: 0.1,
                frictionAir: 0.02,
                frictionStatic: 0.1,
                density: 0.04,
            });

            const moveSpeed = 3 + Math.random() * 2;
            const velocityX = isLeft ? moveSpeed : -moveSpeed;
            const velocityY = (Math.random() - 0.5) * 2;

            Matter.Body.setVelocity(body, { x: velocityX, y: velocityY });

            Matter.Body.setAngularVelocity(body, (Math.random() - 0.5) * 0.05);

            rotationData.set(body.id, {
                speed: (Math.random() * 0.02) + 0.01 * (Math.random() > 0.5 ? 1 : -1),
                current: Math.random() * Math.PI * 2
            });

            textureMap.current.set(body.id, spawnedCount + 1);

            World.add(engine.world, body);
            createdBodies.push(body);
            setBodies([...createdBodies]);

            spawnedCount++;
        }, 200);

        let animationId: number;
        const renderLoop = () => {
            createdBodies.forEach((body) => {
                const el = document.getElementById(`vinyl-${body.id}`);
                const rData = rotationData.get(body.id);

                if (el && rData) {
                    const { x, y } = body.position;
                    rData.current += rData.speed;
                    el.style.transform = `translate3d(${x - vinylRadius}px, ${y - vinylRadius}px, 0) rotate(${rData.current}rad)`;
                }
            });
            animationId = requestAnimationFrame(renderLoop);
        };
        renderLoop();

        const handleResize = () => {
            if (!containerRef.current) return;
            dimensions.width = containerRef.current.clientWidth;
            dimensions.height = containerRef.current.clientHeight;

            const newW = dimensions.width;
            const newH = dimensions.height;

            Matter.Body.setPosition(ground, { x: newW / 2, y: newH + 60 });
            Matter.Body.setPosition(ceiling, { x: newW / 2, y: -60 });
            updateTitleBox();
        };
        window.addEventListener("resize", handleResize);

        const handleMouseMove = (e: MouseEvent) => {
            if (containerRef.current) {
                const rect = containerRef.current.getBoundingClientRect();
                mouse.x = e.clientX - rect.left;
                mouse.y = e.clientY - rect.top;
            }
        };
        window.addEventListener("mousemove", handleMouseMove);

        return () => {
            clearInterval(spawnInterval);
            cancelAnimationFrame(animationId);
            window.removeEventListener("resize", handleResize);
            window.removeEventListener("mousemove", handleMouseMove);
            Runner.stop(runner);
            World.clear(engine.world, false);
            Engine.clear(engine);
            Matter.Events.off(engine, 'beforeUpdate', onBeforeUpdate);
        };
    }, []);

    return (
        <div ref={containerRef} className="absolute inset-0 z-0 overflow-hidden pointer-events-none">
            {bodies.map((body) => {
                const textureIndex = textureMap.current.get(body.id) || 1;
                return (
                    <div
                        key={body.id}
                        id={`vinyl-${body.id}`}
                        className="absolute top-0 left-0 w-[120px] h-[120px]"
                        style={{
                            willChange: "transform",
                        }}
                    >
                        <Image
                            src={`/vinyls/${textureIndex}.png`}
                            alt="Vinyl"
                            width={120}
                            height={120}
                            quality={90}
                            className="w-full h-full object-contain drop-shadow-2xl"
                            style={{ filter: "brightness(0.7)" }}
                        />
                    </div>
                );
            })}
        </div>
    );
}
