import { defineConfig } from 'vite'
import basicSsl from '@vitejs/plugin-basic-ssl'
import dotenv from 'dotenv'
import path from 'path'

dotenv.config()

export default defineConfig(({ command }) => ({
    root: process.cwd(), // ✅ WSL-friendly root
    base: command === 'serve' ? '' : '/app/content/themes/ntdstheme/public/',
    publicDir: false,
    build: {
        assetsDir: '',
        emptyOutDir: true,
        manifest: true,
        outDir: `../app/content/themes/ntdstheme/public`,
        rollupOptions: {
            input: {
                main: path.resolve(process.cwd(), 'src/main.js'),
            }
        },
    },
    server: {
        host: '0.0.0.0',
        port: 5181,
        strictPort: true,
        cors: {
            origin: 'https://willy.ddev.site',
            credentials: true,
        },
        hmr: {
            host: 'localhost',
            clientPort: 5181,
            protocol: 'wss',
        },
        https: true,
        origin: 'https://localhost:5181'
    },
    plugins: [
        basicSsl(),
        {
            name: 'php',
            handleHotUpdate({ file, server }) {
                if (file.endsWith('.php')) {
                    server.ws.send({ type: 'full-reload', path: '*' })
                }
            },
        },
    ],
}))
