import Link from "next/link";

export function Footer() {
    return (
        <footer className="border-t border-zinc-900 px-6 py-12 md:px-12">
            <div className="flex flex-col items-center justify-between gap-6 md:flex-row">
                <p className="text-sm text-zinc-500">© 2026 sourcelocation. All rights reserved.</p>
                <div className="flex gap-8">
                    <a href="https://twitter.com/sourceloc" target="_blank" rel="noopener noreferrer" className="text-sm text-zinc-500 transition-colors hover:text-white">Twitter</a>
                    <a href="https://github.com/sourcelocation" target="_blank" rel="noopener noreferrer" className="text-sm text-zinc-500 transition-colors hover:text-white">GitHub</a>
                    <Link href="/privacy" className="text-sm text-zinc-500 transition-colors hover:text-white">Privacy</Link>
                    <Link href="/license" className="text-sm text-zinc-500 transition-colors hover:text-white">License</Link>
                </div>
            </div>
        </footer>
    );
}
