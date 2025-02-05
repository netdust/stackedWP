import { defineConfig } from "vite";
import laravel from "laravel-vite-plugin";

const appPath = 'public/content/plugins/ntdst_plugin/app';

export default defineConfig({
    plugins: [
        laravel({
            publicDirectory: `${appPath}`,
            input: {
                'assets/main': 'src/assets/main.js',  // Explicitly define input paths
                'blocks/editor': 'src/blocks/editor.js', // Explicitly define input paths
            },
            refresh: true,
        }),
        {
            name: 'php',
            handleHotUpdate({ file, server }) {
                if (file.endsWith('.php')) {
                    server.ws.send({ type: 'full-reload' });
                }
            },
        },
    ],
    build: {
        outDir: `${appPath}`,
        emptyOutDir: false,
        manifest: true,
        watch: {
            include: ["src/**"],
        },
        rollupOptions: {
            output: {
                entryFileNames: '[name].js', // Use [name] directly - no path manipulation needed
                chunkFileNames: `assets/chunks/[name]-[hash].js`,
                assetFileNames: ({ name }) => {
                    const parts = name.split('/');
                    const baseDir = parts[0] === 'blocks' ? 'blocks' : 'assets';
                    return `${baseDir}/[name].[ext]`;
                },
            },
        }
    },
    server: {
        host: 'ntdst.test',
        cors: true,
    }
});