"use client";

import { motion } from "framer-motion";
import Image from "next/image";
import { FileText, MessageCircle } from "lucide-react";
import Link from "next/link";

export function Navbar() {
  return (
    <motion.nav
      initial={{ opacity: 0, y: -20, filter: "blur(10px)" }}
      animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
      transition={{ duration: 2.0, ease: [0.16, 1, 0.3, 1], delay: 0.2 }}
      className="fixed top-0 z-50 flex w-full items-center justify-between px-6 py-8 md:px-12 backdrop-blur-sm bg-black/20"
    >
      <Link href="/" className="flex items-center gap-2">
        <Image src="/app.png" alt="Distribute Logo" width={24} height={24} quality={90} className="rounded" />
        <span className="text-xl font-bold uppercase tracking-widest text-white/90">Distribute</span>
      </Link>
      <div className="flex items-center gap-8">
        <Link href="#" className="hidden text-sm font-medium text-zinc-500 transition-colors hover:text-white md:block">Updates</Link>
        <a href="https://distribute-docs.sourceloc.net/docs" className="hidden text-sm font-medium text-zinc-500 transition-colors hover:text-white md:flex items-center gap-2">
          <FileText className="h-4 w-4" />
          Documentation
        </a>
        <a href="https://discord.gg/X2sZKXhxJj" className="flex items-center gap-2 rounded-full border border-zinc-800 bg-zinc-900/50 px-4 py-2 text-sm font-medium text-white transition-all hover:bg-zinc-800">
          <MessageCircle className="h-4 w-4" />
          Discord
        </a>
      </div>
    </motion.nav>
  );
}
