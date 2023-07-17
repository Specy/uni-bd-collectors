<script lang="ts">
	import { goto } from '$app/navigation';
	import Button from '$cmp/buttons/Button.svelte';
	import Submit from '$cmp/buttons/Submit.svelte';
	import Input from '$cmp/inputs/Input.svelte';
	import Title from '$cmp/layout/Title.svelte';
	import { toast } from '$stores/toastStore';
	import { userStore } from '$stores/userStore';

	let username = 'test';
	let email = 'test@test.com';
	async function login() {
		try {
			const user = await window.api.loginUser(username, email);
			if (!user) return toast.error('Invalid username or email');
			toast.success('Logged in successfully');
			userStore.login(user);
			goto(`/user/${user.id}`);
		} catch (e) {
			toast.error('Error loggin in');
		}
	}
	async function register(){
		try {
			const user = await window.api.createCollector(username, email);
			console.log(user)
			if (!user) return toast.error("Couldn't register");
			toast.success('Registered successfully');
			userStore.login(user);
			goto(`/user/${user.id}`);
		} catch (e) {
			toast.error('Error registering');
		}
	}
</script>

<div class="page">
	<form class="content" on:submit|preventDefault={login}>
		<Title noMargin>Collectors</Title>
		<Input bind:value={username} title="Username" style="background-color: var(--tertiary)" />
		<Input bind:value={email} title="Email" style="background-color: var(--tertiary)" />
		<div class="row" style="width:100%; justify-content: space-between">
			<Button on:click={register} cssVar="tertiary">
				Register
			</Button>
			<Submit value="Login"/>
		</div>
	</form>
</div>

<style>
	.page {
		padding: 2rem;
		display: flex;
		flex-direction: column;
		gap: 1rem;
		align-items: center;
		flex: 1;
		justify-content: center;
	}
	.content {
		display: flex;
		flex-direction: column;
		gap: 1rem;
		background-color: var(--secondary);
		border-radius: 0.6rem;
		padding: 1rem;
		width: 20rem;
	}
</style>
