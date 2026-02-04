"use client";

import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Shield } from "lucide-react";
import Link from "next/link";
import { GridRuler } from "@/components/GridRuler";

export default function PrivacyPage() {
    return (
        <div className="min-h-screen bg-black text-white selection:bg-white selection:text-black overflow-x-clip">
            {/* Background System */}
            <div className="fixed inset-0 z-0 pointer-events-none">
                <GridRuler />
                <div
                    className="absolute top-0 left-1/2 -translate-x-1/2 h-[600px] w-full max-w-[1400px] opacity-20 mix-blend-screen"
                    style={{
                        background: "radial-gradient(circle at center, rgba(59, 130, 246, 0.4) 0%, rgba(59, 130, 246, 0) 60%)"
                    }}
                />
            </div>

            <nav className="fixed top-0 z-50 flex w-full items-center justify-between px-6 py-8 md:px-12 backdrop-blur-sm bg-black/20">
                <Link href="/" className="flex items-center gap-2 group">
                    <ArrowLeft className="h-4 w-4 text-zinc-500 group-hover:text-white transition-colors" />
                    <span className="text-sm font-medium text-zinc-500 group-hover:text-white transition-colors">Back to home</span>
                </Link>
            </nav>

            <main className="relative z-10 flex flex-col items-center justify-center min-h-screen px-6 pt-32 pb-24 text-center">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
                    className="max-w-2xl w-full"
                >
                    <div className="mb-8 flex justify-center">
                        <div className="relative">
                            <div className="absolute inset-0 bg-blue-500/20 blur-2xl rounded-full" />
                            <div className="relative h-16 w-16 rounded-2xl border border-white/10 bg-zinc-900/50 flex items-center justify-center backdrop-blur-xl">
                                <Shield className="h-8 w-8 text-blue-400" />
                            </div>
                        </div>
                    </div>

                    <h1 className="text-4xl md:text-6xl font-bold tracking-tight mb-6 bg-gradient-to-b from-white to-zinc-500 bg-clip-text text-transparent">
                        Privacy Policy
                    </h1>

                    <div className="space-y-8 text-left bg-zinc-900/30 border border-zinc-800/50 p-8 md:p-12 rounded-3xl backdrop-blur-md">
                        <section>
                            <h2 className="text-xl font-semibold text-white mb-4">Our Commitment</h2>
                            <p className="text-zinc-400 leading-relaxed text-lg">
                                Distribute is built on the principle of digital sovereignty. We believe your data should belong to you, and only you.
                            </p>
                        </section>

                        <section className="pt-4 border-t border-zinc-800/50">
                            <h2 className="text-5xl font-bold text-white mb-4 tracking-tight">We collect nothing.</h2>
                            <p className="text-zinc-500 leading-relaxed">
                                No tracking. No analytics. No telemetry. No cloud sync of your private library to our servers. Your music, your server, your privacy.
                            </p>
                        </section>
                    </div>

                    <footer className="mt-12 text-zinc-600 text-sm">
                        Last updated: January 6, 2026
                    </footer>
                </motion.div>
            </main>
        </div>
    );
}
