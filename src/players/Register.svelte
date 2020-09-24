<script>
  import {
    Alert,
    Row,
    Col,
    FormGroup,
    Input,
    Label,
    Button,
  } from "sveltestrap";
  import gomoku from "ic:canisters/gomoku";

  let playerName;
  let errorMessage;

  async function handleSubmit() {
    gomoku
      .register(playerName)
      .then((result) => {
        if ("ok" in result) {
          errorMessage = "OK";
        } else {
          let error_code = Object.keys(result["err"])[0];
          if (error_code == "NameAlreadyExists") {
            errorMessage =
              "Name '" +
              (playerName ? playerName : "") +
              "' was already taken.";
          }
        }
      })
      .catch((err) => {
        console.log(err);
        errorMessage = "An error occured while registering.";
      });
  }
</script>

<Row>
  <Col class="d-flex justify-content-center">
    <h1>Register</h1>
  </Col>
</Row>
<Row>
  <form on:submit|preventDefault={handleSubmit}>
    <FormGroup>
      <Label for="playerName">Your player name</Label>
      <Input type="text" bind:value={playerName} />
    </FormGroup>
    <Alert isOpen={errorMessage ? true : false} color="warning">
      {errorMessage}
    </Alert>
    <Button primary type="submit">Submit</Button>
  </form>
</Row>
