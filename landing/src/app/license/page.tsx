"use client";

import { motion } from "framer-motion";
import { GridRuler } from "@/components/GridRuler";
import { ArrowLeft, Scale, FileText, ShieldCheck } from "lucide-react";
import Link from "next/link";
import { Button } from "@/components/ui/button";

export default function LicensePage() {
    return (
        <div className="min-h-screen bg-black text-white selection:bg-white selection:text-black overflow-x-hidden">
            {/* Background Elements */}
            <div className="fixed inset-0 z-0 pointer-events-none">
                <GridRuler />
                <div
                    className="absolute top-0 left-1/2 -translate-x-1/2 h-[600px] w-full max-w-[1400px] opacity-20 mix-blend-screen"
                    style={{
                        background: "radial-gradient(circle at center, rgba(59, 130, 246, 0.3) 0%, rgba(59, 130, 246, 0) 60%)"
                    }}
                />
            </div>

            <motion.div
                initial={{ opacity: 0, y: -20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.8, ease: [0.16, 1, 0.3, 1] }}
                className="relative z-10 container mx-auto px-6 py-12 md:py-24 max-w-4xl"
            >
                <Link href="/" className="inline-block mb-12">
                    <Button variant="ghost" className="text-zinc-400 hover:text-white hover:bg-white/10 gap-2 pl-0">
                        <ArrowLeft className="h-4 w-4" />
                        Back to Home
                    </Button>
                </Link>

                <header className="mb-16">
                    <motion.div
                        initial={{ opacity: 0, scale: 0.9 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ duration: 1, delay: 0.2, ease: [0.16, 1, 0.3, 1] }}
                        className="inline-flex items-center justify-center p-3 mb-6 rounded-2xl bg-zinc-900/50 border border-zinc-800 backdrop-blur-sm shadow-xl"
                    >
                        <Scale className="h-8 w-8 text-white" />
                    </motion.div>

                    <motion.h1
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.3, ease: [0.16, 1, 0.3, 1] }}
                        className="text-4xl md:text-6xl font-bold tracking-tight mb-6 bg-gradient-to-b from-white to-zinc-400 bg-clip-text text-transparent"
                    >
                        License Information
                    </motion.h1>

                    <motion.p
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.4, ease: [0.16, 1, 0.3, 1] }}
                        className="text-lg md:text-xl text-zinc-400 max-w-2xl leading-relaxed"
                    >
                        Distribute is open source software. We believe in transparency and community-driven development.
                    </motion.p>
                </header>

                <section className="space-y-8">
                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.5, ease: [0.16, 1, 0.3, 1] }}
                        className="relative overflow-hidden rounded-3xl border border-zinc-800 bg-zinc-900/30 backdrop-blur-md"
                    >
                        <div className="absolute top-0 right-0 p-32 bg-blue-500/10 blur-[100px] rounded-full pointer-events-none" />

                        <div className="p-8 md:p-12">
                            <div className="flex items-center gap-4 mb-8">
                                <div className="p-2 rounded-lg bg-zinc-800/50 border border-zinc-700/50">
                                    <FileText className="h-5 w-5 text-zinc-300" />
                                </div>
                                <h2 className="text-xl font-semibold text-white">MIT License</h2>
                            </div>

                            <div className="font-mono text-sm md:text-base text-zinc-400 leading-relaxed whitespace-pre-wrap">
                                {`MIT License

Copyright (c) 2026 sourcelocation

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.`}
                            </div>
                        </div>
                    </motion.div>

                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.8, delay: 0.6, ease: [0.16, 1, 0.3, 1] }}
                        className="grid grid-cols-1 md:grid-cols-2 gap-6"
                    >
                        <div className="rounded-2xl border border-zinc-800 bg-zinc-900/30 p-8 backdrop-blur-sm">
                            <ShieldCheck className="h-8 w-8 text-emerald-500 mb-4" />
                            <h3 className="text-lg font-semibold text-white mb-2">Permissive</h3>
                            <p className="text-zinc-400 text-sm leading-relaxed">
                                You are free to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the software.
                            </p>
                        </div>

                        <div className="rounded-2xl border border-zinc-800 bg-zinc-900/30 p-8 backdrop-blur-sm">
                            <div className="h-8 w-8 rounded-full border border-zinc-700 bg-zinc-800 flex items-center justify-center text-xs font-bold text-zinc-300 mb-4">?</div>
                            <h3 className="text-lg font-semibold text-white mb-2">No Warranty</h3>
                            <p className="text-zinc-400 text-sm leading-relaxed">
                                The software is provided "as is", without warranty of any kind. We are not liable for any damages or claims.
                            </p>
                        </div>
                    </motion.div>
                </section>

                <motion.footer
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    transition={{ duration: 1, delay: 0.8 }}
                    className="mt-24 border-t border-zinc-900 pt-8"
                >
                    <p className="text-center text-sm text-zinc-600">
                        For meaningful contributions or commercial inquiries, please contact us on Discord.
                    </p>
                </motion.footer>
            </motion.div>
        </div>
    );
}
