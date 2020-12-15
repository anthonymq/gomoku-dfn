<script>
  import { Col, Row } from "sveltestrap";
  import RecentPlayers from "./players/RecentPlayers.svelte";
  import Register from "./players/Register.svelte";
  import RegisterPicture from "./players/RegisterPicture.svelte";
</script>

<Row>
  <Col class="d-flex justify-content-center">
    <h1>Gomoku on the Internet Computer</h1>
  </Col>
</Row>
<Row>
  <Col xs="3">
    <RecentPlayers />
  </Col>
  <Col>
    <Register />
  </Col>
  <Col>
    <RegisterPicture />
  </Col>
</Row>
