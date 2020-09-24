<script>
  import { onMount } from "svelte";
  import { Col, Row, ListGroup, ListGroupItem } from "sveltestrap";
  import gomoku from "ic:canisters/gomoku";
  export let players = [];

  async function refreshPlayers() {
    gomoku.list().then((resp) => {
      players = resp.recent;
    });
  }

  onMount(() => {
    refreshPlayers();
    const interval = setInterval(() => {
      refreshPlayers();
    }, 5000);

    return () => {
      clearInterval(interval);
    };
  });
</script>

<style>

</style>

<Row>
  <Col class="d-flex justify-content-center">
    <h1>Recent players</h1>
  </Col>

</Row>
<Row>
  <Col>
    <ListGroup>
      {#each players as player}
        <ListGroupItem>{player.name} x {player.score}</ListGroupItem>
      {/each}
    </ListGroup>
  </Col>
</Row>
