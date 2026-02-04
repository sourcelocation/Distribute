"use client";

import { motion } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ArrowRight, Monitor, Smartphone, Download, Command } from "lucide-react";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { useEffect, useState } from "react";
import Link from "next/link";

type Platform = "windows" | "mac" | "linux" | "android" | "ios";

const DOWNLOAD_LINKS: Record<Platform, string> = {
    windows: "https://github.com/ProjectDistribute/Distribute/releases/latest",
    mac: "https://github.com/ProjectDistribute/Distribute/releases/latest",
    linux: "https://github.com/ProjectDistribute/Distribute/releases/latest",
    android: "https://github.com/ProjectDistribute/Distribute/releases/latest",
    ios: "https://testflight.apple.com/join/DA8bhKJH",
};

const PLATFORM_NAMES: Record<Platform | "unknown", string> = {
    windows: "Windows",
    mac: "macOS",
    linux: "Linux",
    android: "Android",
    ios: "iOS",
    unknown: "your device",
};

const PLATFORM_ICONS: Record<Platform | "unknown", any> = {
    windows: Monitor,
    mac: Command,
    linux: Monitor,
    android: Smartphone,
    ios: Smartphone,
    unknown: Download,
};

export default function DownloadsPage() {
    const [platform, setPlatform] = useState<Platform | "unknown">("unknown");

    useEffect(() => {
        const userAgent = navigator.userAgent.toLowerCase();
        if (userAgent.includes("win")) setPlatform("windows");
        else if (userAgent.includes("mac")) setPlatform("mac");
        else if (userAgent.includes("linux")) setPlatform("linux");
        else if (userAgent.includes("android")) setPlatform("android");
        else if (userAgent.includes("iphone") || userAgent.includes("ipad") || userAgent.includes("ipod")) setPlatform("ios");
    }, []);

    const downloadUrl = platform === "unknown" ? DOWNLOAD_LINKS.windows : DOWNLOAD_LINKS[platform];

    return (
        <div className="min-h-screen bg-black text-white selection:bg-white selection:text-black overflow-x-hidden">
            <div className="fixed inset-0 z-0 pointer-events-none">
                <div
                    className="absolute top-0 left-1/2 -translate-x-1/2 h-[600px] w-full max-w-[1400px] opacity-30 mix-blend-screen"
                    style={{
                        background: "radial-gradient(circle at center, rgba(59, 130, 246, 0.4) 0%, rgba(59, 130, 246, 0) 60%)"
                    }}
                />
            </div>

            <Navbar />

            <main className="relative z-10 flex flex-col items-center pt-32 md:pt-48 min-h-[80vh] pb-32">
                <section className="relative flex flex-col items-center px-6 text-center max-w-5xl w-full">
                    <motion.div
                        initial={{ opacity: 0, y: 20, filter: "blur(7px)" }}
                        animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
                        transition={{ duration: 0.3 }}
                        className="mb-12"
                    >
                        <Badge variant="outline" className="mb-6 border-zinc-800 bg-black/50 py-1.5 text-zinc-400 backdrop-blur-md">
                            Downloads
                        </Badge>
                        <h1 className="text-4xl font-bold tracking-tight md:text-6xl lg:text-7xl mb-6">
                            Get Distribute
                        </h1>
                        <p className="max-w-2xl mx-auto text-lg text-zinc-400 md:text-xl leading-relaxed">
                            Available on all your devices. Connect your server and start streaming.
                        </p>
                    </motion.div>

                    {/* Primary Download */}
                    <motion.div
                        initial={{ opacity: 0, scale: 0.95, filter: "blur(7px)" }}
                        animate={{ opacity: 1, scale: 1, filter: "blur(0px)" }}
                        transition={{ duration: 0.3, delay: 0.2 }}
                        className="w-full max-w-md p-1 rounded-3xl bg-gradient-to-b from-white/10 to-transparent mb-24"
                    >
                        <div className="relative flex flex-col items-center p-8 bg-zinc-950/90 backdrop-blur-xl rounded-[22px] border border-white/5 shadow-2xl">
                            <div className="absolute inset-x-0 -top-px h-px bg-gradient-to-r from-transparent via-white/20 to-transparent" />

                            <div className="mb-6 p-4 rounded-full bg-white/5 border border-white/10">
                                {(() => {
                                    const Icon = PLATFORM_ICONS[platform];
                                    return <Icon className="w-8 h-8 text-white" />;
                                })()}
                            </div>

                            <h2 className="text-2xl font-bold mb-2">Download for {PLATFORM_NAMES[platform]}</h2>
                            <p className="text-zinc-500 mb-8 text-sm">Latest Version • Free</p>

                            <Button size="lg" className="w-full h-12 rounded-full bg-white text-black hover:bg-zinc-200 transition-all font-semibold" asChild>
                                <a href={downloadUrl}>
                                    Download Now
                                    <ArrowRight className="ml-2 h-4 w-4" />
                                </a>
                            </Button>
                        </div>
                    </motion.div>

                    {/* Other Platforms */}
                    <motion.div
                        initial={{ opacity: 0, y: 20 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        viewport={{ once: true }}
                        transition={{ duration: 0.8 }}
                        className="w-full"
                    >
                        <h3 className="text-xl font-semibold mb-12 text-zinc-400">All Platforms</h3>
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 w-full">
                            {(Object.keys(DOWNLOAD_LINKS) as Platform[]).map((p) => {
                                const Icon = PLATFORM_ICONS[p];
                                return (
                                    <Link
                                        key={p}
                                        href={DOWNLOAD_LINKS[p]}
                                        className="flex items-center gap-4 p-4 rounded-xl border border-zinc-800 bg-zinc-900/30 hover:bg-zinc-900/50 transition-all group"
                                    >
                                        <div className="p-2 rounded-lg bg-zinc-800 text-zinc-400 group-hover:text-white transition-colors">
                                            <Icon className="w-5 h-5" />
                                        </div>
                                        <div className="text-left flex-1">
                                            <div className="font-medium text-zinc-200 group-hover:text-white transition-colors">{PLATFORM_NAMES[p]}</div>
                                            <div className="text-xs text-zinc-500">Download</div>
                                        </div>
                                        <ArrowRight className="w-4 h-4 text-zinc-600 group-hover:text-zinc-400 transition-colors -translate-x-2 opacity-0 group-hover:translate-x-0 group-hover:opacity-100" />
                                    </Link>
                                );
                            })}
                        </div>
                    </motion.div>
                </section>
            </main>

            <Footer />
        </div>
    );
}
