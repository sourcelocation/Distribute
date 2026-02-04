"use client";

import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ArrowRight } from "lucide-react";
import Image from "next/image";
import dynamic from "next/dynamic";
import { useState, useRef } from "react";
import { VinylAnimation } from "@/components/VinylAnimation";
import { GridRuler } from "@/components/GridRuler";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import Link from 'next/link';

const FeaturesGrid = dynamic(() => import("@/components/FeaturesGrid").then(mod => mod.FeaturesGrid), { ssr: false });
const AppLayersAnimation = dynamic(() => import("@/components/AppLayersAnimation").then(mod => mod.AppLayersAnimation), { ssr: false });
const PiracyDisclaimer = dynamic(() => import("@/components/PiracyDisclaimer").then(mod => mod.PiracyDisclaimer), { ssr: false });
const VinylPhysics = dynamic(() => import("@/components/VinylPhysics").then(mod => mod.VinylPhysics), { ssr: false });

const transition = {
  duration: 1,
  ease: [0.16, 1, 0.3, 1] as const,
};

const fadeInUp = {
  initial: { opacity: 0, y: 20 },
  animate: { opacity: 1, y: 0 },
  transition,
};

const stagger = {
  animate: {
    transition: {
      staggerChildren: 0.1,
    },
  },
};

export default function Home() {
  return (
    <div className="min-h-screen bg-black text-white selection:bg-white selection:text-black overflow-x-clip">
      <div className="fixed inset-0 z-0 pointer-events-none">
        <GridRuler />

        <div
          className="absolute top-0 left-1/2 -translate-x-1/2 h-[600px] w-full max-w-[1400px] opacity-30 mix-blend-screen"
          style={{
            background: "radial-gradient(circle at center, rgba(59, 130, 246, 0.4) 0%, rgba(59, 130, 246, 0) 60%)"
          }}
        />
      </div>

      <Navbar />

      <main className="relative z-10 flex flex-col items-center pt-32 md:pt-48">
        <section className="relative flex flex-col items-center px-6 text-center">


          <motion.div
            initial={{ opacity: 0, scale: 0.8, filter: "blur(10px)" }}
            animate={{ opacity: 1, scale: 1, filter: "blur(0px)" }}
            transition={{ duration: 1.2, delay: 0.4, ease: [0.16, 1, 0.3, 1] }}
            className="relative z-10 mb-10"
          >
            <div className="relative">
              <div className="absolute inset-0 bg-white/20 blur-2xl rounded-full" />
              <Image
                src="/app.png"
                alt="Distribute Logo"
                width={64}
                height={64}
                quality={90}
                className="relative rounded-2xl shadow-2xl border border-white/10"
              />
            </div>
          </motion.div>

          <VinylAnimation />

          <motion.h1
            initial="hidden"
            animate="visible"
            variants={{
              visible: { transition: { staggerChildren: 0.1 } },
              hidden: {},
            }}
            className="relative z-10 mb-6 max-w-4xl text-6xl font-bold tracking-tight md:text-7xl lg:text-8xl"
            aria-label="Your music. Your server. Period."
          >
            {"Your music. Your server. Period.".split(" ").map((word, i) => (
              <motion.span
                key={i}
                variants={{
                  hidden: { opacity: 0, y: 20, filter: "blur(10px)" },
                  visible: { opacity: 1, y: 0, filter: "blur(0px)", transition: { duration: 0.8, ease: [0.2, 0.65, 0.3, 0.9] } },
                }}
                className="inline-block mr-4 last:mr-0 text-white"
              >
                {word}
              </motion.span>
            ))}
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 20, filter: "blur(10px)" }}
            animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
            transition={{ duration: 1, delay: 0.8, ease: [0.16, 1, 0.3, 1] }}
            className="relative z-10 mb-12 max-w-2xl text-lg text-zinc-400 md:text-xl lg:text-2xl leading-relaxed"
          >
            Distribute is an offline-first streaming music app that connects to your home server.
            Cross-sync servers to expand your library.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20, filter: "blur(10px)" }}
            animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
            transition={{ duration: 1, delay: 1, ease: [0.16, 1, 0.3, 1] }}
            className="relative z-10 flex flex-col items-center gap-6 sm:flex-row"
          >
            <Button size="lg" className="h-14 rounded-full bg-white px-10 text-base font-semibold text-black transition-all hover:bg-zinc-200 hover:scale-105 active:scale-95" asChild>
              <Link href="/downloads">Download App</Link>
            </Button>
            <Button variant="ghost" size="lg" className="h-14 rounded-full text-base font-medium text-zinc-400 hover:text-white hover:bg-white/10 transition-all" asChild>
              <a href="https://discord.gg/X2sZKXhxJj">Join the Community</a>
            </Button>
          </motion.div>
        </section>

        <FeaturesGrid />

        <AppLayersAnimation />

        <PiracyDisclaimer />

        <ClosingSection />
      </main>

      <Footer />
    </div>
  );
}

function ClosingSection() {
  const [startPhysics, setStartPhysics] = useState(false);
  const titleRef = useRef<HTMLHeadingElement>(null);

  return (
    <motion.section
      initial={{ opacity: 0 }}
      whileInView={{ opacity: 1 }}
      onViewportEnter={() => setStartPhysics(true)}
      viewport={{ once: true, amount: 0.3 }}
      transition={{ duration: 1 }}
      className="relative mt-48 flex min-h-[600px] w-full flex-col items-center justify-center overflow-hidden px-6 text-center"
    >
      {startPhysics && <VinylPhysics titleRef={titleRef} />}

      <div className="relative z-10 flex flex-col items-center">
        <Badge variant="outline" className="mb-6 border-zinc-800 bg-black/50 py-1.5 text-zinc-400 backdrop-blur-md">
          Ready to start?
        </Badge>
        <h2 ref={titleRef} className="mb-8 max-w-2xl text-4xl font-bold tracking-tight md:text-6xl text-white drop-shadow-2xl">
          Stop renting your music. Install Distribute.
        </h2>
        <Button
          size="lg"
          className="h-14 rounded-full bg-white px-10 text-base font-semibold text-black transition-all hover:scale-105 active:scale-95 hover:bg-zinc-200 shadow-xl"
          asChild
        >
          <Link href="/downloads">
            Download App
            <ArrowRight className="ml-2 h-5 w-5" />
          </Link>
        </Button>
      </div>


    </motion.section>
  );
}

