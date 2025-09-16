import { defineConfig } from 'vite'
import basicSsl from '@vitejs/plugin-basic-ssl'
import dotenv from 'dotenv'
import path from 'path'

dotenv.config({ path: path.resolve(process.cwd(), `.env.local`) });

export default defineConfig(({ command }) => ({
    root: process.cwd(), // ✅ WSL-friendly root
    base: command === 'serve' ? '' :  process.env.VITE_THEME ? `/content/themes/${process.env.VITE_THEME}/assets/dist/` : '/dist/',
    publicDir: false,
    build: {
        assetsDir: '',
        emptyOutDir: true,
        manifest: true,
        outDir: `./app/content/themes/${process.env.VITE_THEME}/assets/dist/`,
        rollupOptions: {
            input: {
                main: path.resolve(process.cwd(), process.env.VITE_ENTRY_POINT || 'src/main.js'),
            }
        },
    },
    server: {
        host: process.env.VITE_HOST || 'localhost',
        port: parseInt(process.env.VITE_PORT) || 5181,
        strictPort: true,
        cors: {
            origin: process.env.WP_HOME,
            credentials: true,
        },
        hmr: {
            host: process.env.VITE_HOST || 'localhost',
            clientPort: parseInt(process.env.VITE_PORT) || 5181,
            protocol: 'wss',
        },
        https: process.env.VITE_PROTOCOL === 'https',
        origin: `${process.env.VITE_PROTOCOL || 'http'}://${process.env.VITE_HOST || 'localhost'}:${process.env.VITE_PORT || 5173}`
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
