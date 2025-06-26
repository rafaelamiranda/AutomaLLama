import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
	
	// CORREÇÃO: Definir o base path corretamente
	base: process.env.VITE_BASE_URL || '/open-webui/',
	
	build: {
		target: 'esnext',
		sourcemap: false,
		// CORREÇÃO: Garantir que os assets sejam relativos ao base path
		assetsDir: 'assets',
		rollupOptions: {
			output: {
				// Garantir que os chunks tenham nomes consistentes
				chunkFileNames: 'assets/[name]-[hash].js',
				entryFileNames: 'assets/[name]-[hash].js',
				assetFileNames: 'assets/[name]-[hash].[ext]'
			}
		}
	},
	
	server: {
		host: '0.0.0.0',
		port: 5173
	},
	
	define: {
		// Tornar a base URL disponível no runtime
		__VITE_BASE_URL__: JSON.stringify(process.env.VITE_BASE_URL || '/open-webui/')
	}
});