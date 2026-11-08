<script>
	let { children } = $props();
</script>

<svelte:head>
	<!-- Ícono de la pestaña: emblema del logo de la tienda -->
	<link rel="icon" type="image/png" sizes="64x64" href="/favicon.png" />
	<link rel="icon" href="/favicon.ico" sizes="any" />
	<link rel="apple-touch-icon" href="/apple-touch-icon.png" />
	<meta name="theme-color" content="#0d0d0d" />
</svelte:head>

{@render children()}
