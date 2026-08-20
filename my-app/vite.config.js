import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
		port: process.env.PORT || 4173, // Usa el puerto proporcionado por Render o 4173 como fallback
		host: '0.0.0.0', // Hace que la aplicación esté accesible desde cualquier IP
	},
	preview: {
		allowedHosts: ['sensutrack-front.onrender.com'], // Agrega tu dominio aquí
	},
	build: {
		outDir: 'build', // Especificamos el directorio de salida para la construcción
	},
});

// import { sveltekit } from '@sveltejs/kit/vite';
// import { defineConfig } from 'vite';

// export default defineConfig({
// 	plugins: [sveltekit()]
// });


// import adapter from '@sveltejs/adapter-auto';
// import { sveltekit } from '@sveltejs/kit/vite';
// import { defineConfig } from 'vite';

// export default defineConfig({
// 	plugins: [
// 		sveltekit({
// 			compilerOptions: {
// 				// Force runes mode for the project, except for libraries. Can be removed in svelte 6.
// 				runes: ({ filename }) =>
// 					filename.split(/[/\\]/).includes('node_modules') ? undefined : true
// 			},

// 			// adapter-auto only supports some environments, see https://svelte.dev/docs/kit/adapter-auto for a list.
// 			// If your environment is not supported, or you settled on a specific environment, switch out the adapter.
// 			// See https://svelte.dev/docs/kit/adapters for more information about adapters.
// 			adapter: adapter()
// 		})
// 	]
// });
