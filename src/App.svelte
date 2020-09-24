<script>
  import { Container, Col, Row } from "sveltestrap";
  import { Router, Route, Link, router } from "yrv";

  Router.hashchange = true;
</script>

<style>
  h1 {
    color: purple;
  }
</style>

<head>
  <link
    rel="stylesheet"
    href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" />
</head>

<Container>
  <Link reload href="/">Home</Link>
  |
  <Link reload href="/register">Registration</Link>
  |
  <Link reload href="/list">Players</Link>

  <Router>
    <Route exact
      path="/"
      component={() => import('./Home.svelte')}
    />
    <Route
      exact
      path="/register"
      component={() => import('./players/Register.svelte')} />
    <Route
      exact
      path="/list"
      component={() => import('./players/RecentPlayers.svelte')} />
    <Route
      exact
      path="/board"
      component={() => import('./game/Board.svelte')} />
  </Router>
</Container>
