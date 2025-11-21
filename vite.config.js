import { defineConfig } from 'vite'
import basicSsl from '@vitejs/plugin-basic-ssl'
import path from 'path'

import { fileURLToPath } from 'url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

await (await import('dotenv')).default.config({
    path: path.resolve(process.cwd(), '.env.local')
})

export default defineConfig(({ command }) => ({
    root: process.cwd(), // ✅ WSL-friendly root
    base: command === 'serve' ? '' :  process.env.VITE_THEME ? `/app/content/themes/${process.env.VITE_THEME}/assets/dist/` : '/dist/',
    publicDir: false,
    define: {
        VERSION: JSON.stringify('3.24.2'),
        LOG: 'false',
    },
    build: {
        assetsDir: '',
        emptyOutDir: true,
        manifest: true,
        outDir: `./app/content/themes/${process.env.VITE_THEME}/assets/dist/`,
        rollupOptions: {
            input: {
                'uikit-custom': path.resolve(process.cwd(), 'src/uikit-custom.js'),
                'theme-services': path.resolve(process.cwd(), 'src/theme-services.js'),
                'ntdst-custom': path.resolve(process.cwd(), 'src/ntdst-custom.js'),
            },
            output: {
                format: 'es',
                entryFileNames: '[name].js',
                chunkFileNames: 'chunks/[name]-[hash].js',
                assetFileNames: 'assets/[name]-[hash][extname]'
            },
        },
    },
    resolve: {
        alias: {
            '@': process.cwd(),
            'uikit': path.resolve(__dirname, 'node_modules/uikit/src/js'),
            'uikit-util': path.resolve(__dirname, 'node_modules/uikit/src/js/util'),
        },
        dedupe: ['uikit'],
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