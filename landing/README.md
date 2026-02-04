<div align="center">
  <img src="github-assets/banner.png" alt="Distribute Banner" width="100%" />

  <h1>Distribute (Web)</h1>
  
  <p>
    <strong>The official landing page for the Distribute music app.</strong>.
  </p>

  <p>
    <a href="https://nextjs.org/"><img src="https://img.shields.io/badge/Next.js-16-black?style=flat-square&logo=next.js" alt="Next.js"></a>
    <a href="https://react.dev/"><img src="https://img.shields.io/badge/React-19-blue?style=flat-square&logo=react" alt="React"></a>
    <a href="https://tailwindcss.com/"><img src="https://img.shields.io/badge/Tailwind_CSS-4-38B2AC?style=flat-square&logo=tailwind-css" alt="Tailwind CSS"></a>
    <a href="https://www.framer.com/motion/"><img src="https://img.shields.io/badge/Motion-Framer-0055FF?style=flat-square&logo=framer" alt="Framer Motion"></a>
  </p>

  <p>
    <a href="#-community">Discord</a> •
    <a href="#-about-this-project">About This Project</a> •
    <a href="#-about-distribute-the-product">Distribute App</a> •
    <a href="#-getting-started">Getting Started</a> •
    <a href="#%EF%B8%8F-tech-stack">Tech Stack</a>
  </p>
</div>

---

## 🤝 Community

- [Discord](https://discord.gg/X2sZKXhxJj).
- [Twitter @sourceloc](https://twitter.com/sourceloc).

---

## 📖 About This Project

This repository contains the source code for the **public-facing marketing website** of Distribute.

> [!IMPORTANT]
> **This is NOT the Distribute music application.**
> 
> This repo houses the **landing page** only. The actual Distribute client and server application are developed and hosted in separate repositories. Links:
> 
> - [Distribute App](https://github.com/ProjectDistribute/app)
> - [Distributor](https://github.com/ProjectDistribute/distributor)

## 🎵 About Distribute

The landing page promotes **Distribute**, a next-generation, offline-first music streaming application designed for privacy-conscious audiophiles.

| Product Feature | Description |
| :--- | :--- |
| **Self-Hosted Core** | Connect to your own home server. Your music, your rules. |
| **Offline-First** | Local-first architecture ensures music plays without internet. |
| **Library Sync** | Smart synchronization between multiple servers. |
| **Privacy Focused** | Zero tracking. Absolute user privacy and data ownership. |

## ⚡ Website Features (This Repository)

This landing page project showcases modern web development techniques:

*   **Interactive Physics**: Custom **Matter.js** implementation for the interactive vinyl section.
*   **Scroll-Driven Animations**: Complex scroll reveals using **Framer Motion**.
*   **Modern Stack**: Built on **Next.js 16** and **React 19** with Server Components.
*   **Design System**: Styled with **Tailwind CSS 4** and **Shadcn UI**.

## 🛠️ Tech Stack

This website is built with the following technologies:

- **Frontend Framework**: [Next.js 16](https://nextjs.org/) (App Router)
- **UI Library**: [React 19](https://react.dev/)
- **Styling**: [Tailwind CSS 4](https://tailwindcss.com/)
- **Animations**: [Framer Motion](https://www.framer.com/motion/)
- **Physics**: [Matter.js](https://brm.io/matter-js/)
- **Components**: [Shadcn UI](https://ui.shadcn.com/)
- **Icons**: [Lucide React](https://lucide.dev/)

## 🚀 Getting Started

Follow these steps to run the **landing page** locally.

### Prerequisites

- **Node.js** v18+
- **npm** or **yarn**

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/sourcelocation/distribute.git
    cd distribute/web
    ```

2.  **Install dependencies**
    ```bash
    npm install
    # or
    yarn install
    ```

3.  **Start the development server**
    ```bash
    npm run dev
    # or
    yarn dev
    ```

4.  **View the site**
    Open [http://localhost:3000](http://localhost:3000) to view the landing page.

## 📂 Project Structure

```text
web/
├── public/              # Static assets (site images, vinyl textures)
├── src/
│   ├── app/             # Next.js App Router pages
│   ├── components/      # React components (Landing sections, animations)
│   │   ├── ui/          # Shared UI components
│   │   └── ...          # Feature-specific components
│   └── lib/             # Utility functions
├── next.config.ts       # Next.js configuration
├── tailwind.config.ts   # Tailwind CSS configuration
└── package.json         # Project dependencies
```

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

<div align="center">
  Built with ❤️ by <a href="https://github.com/sourcelocation">sourcelocation</a>
</div>
