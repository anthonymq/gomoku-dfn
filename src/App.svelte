<script>
	import gomoku from 'ic:canisters/gomoku';
	export let name;

	gomoku.greet(window.prompt("Enter your name:")).then(greeting => {
		window.alert(greeting);
	});
</script>

<style>
	h1 {
		color: purple;
	}
</style>

<h1>Hello {name}!</h1>