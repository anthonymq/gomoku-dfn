<script>
  import { Button, Col, Row } from "sveltestrap";

  import gomoku from "ic:canisters/gomoku";
  export let name;
  export let greeting;

  gomoku.greet("lol").then((resp) => {
    greeting = resp;
  });
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
<Row>
  <Col>
    <h1>Hello {name}!</h1>
  </Col>
</Row>
<!-- <Row><h1>{greeting}</h1></Row> -->
<Row>
  <Col>
    <Button color="primary" outline>Hello World!</Button>
  </Col>
</Row>
