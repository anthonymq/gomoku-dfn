<script>
  import {
    Row,
    Col,
    FormGroup,
    Input,
    Label,
    Button,
  } from "sveltestrap";
  import BigMap from "ic:canisters/BigMap";
  import { v4 as uuidv4 } from "uuid";

  let files;
  let fileId = "";
  let blobImage = "";
  const CHUNK_SIZE = 1025 * 500;
  const encoder = new TextEncoder();
  const decoder = new TextDecoder();

  async function handleSubmit() {
    const file = files[0];
    fileId = uuidv4();
    const fileSize = file.size;
    const fileBuffer = await file.arrayBuffer();
    const fileName = file.name;
    const playlist = [];
    let chunk = 0;
    const chunksData = {};

    const fileUrl = `files/${fileId}`;
    for (let byteStart = 0; byteStart < fileSize; byteStart += CHUNK_SIZE) {
      const fileSlice = fileBuffer.slice(
        byteStart,
        Math.min(fileSize, byteStart + CHUNK_SIZE)
      );
      const fileSlicePath = `files/${fileId}/chunks/chunk.${chunk}`;
      const chunkData = Array.from(new Uint8Array(fileSlice));
      chunksData[chunk] = chunkData;
      chunk++;
      playlist.push(fileSlicePath);
    }
    console.log(playlist);

    const promises = [];
    for (let c = 0; c < Object.values(chunksData).length; c++) {
      const fileSlicePath = `files/${fileId}/chunks/chunk.${c}`;
      promises.push(
        BigMap.put(Array.from(encoder.encode(fileSlicePath)), 
        chunksData[c]
        )
      );
    }

    await Promise.all(promises);

    const metadata = {
      id: fileId,
      createdAt: `${Date.now()}`,
      chunks: {
        manifest: playlist,
        size: fileSize,
      },
      name: fileName,
      type: file.type,
    };

    await BigMap.put(
      Array.from(encoder.encode(`files/${fileId}/metadata`)),
      Array.from(encoder.encode(JSON.stringify(metadata)))
    );
    console.log(metadata);
    return metadata;
  }

  async function getFile() {
    const fileUrl = `files/${fileId}`;
    const metaUrl = `files/${fileId}/metadata`;

    const metaUrlEncoded = Array.from(encoder.encode(metaUrl));

    console.log("get", metaUrl);
    console.log("get", metaUrlEncoded);

    const metadataVec = await BigMap.get(metaUrlEncoded);
    if (!metadataVec) {
      return console.error("metadata not found");
    }

    const metadata = JSON.parse(decoder.decode(new Uint8Array(metadataVec[0])));
    console.log(metadata);

    const chunkBuffers = [];
    let bufferSize = 0;

    try {
      const { manifest, size } = metadata.chunks;
      bufferSize = size;
      console.log("manifest", manifest);
      console.log("size", size);
      await Promise.all(
        manifest.map(async (chunkKeyStr, index) => {
          console.log("chunkKeyStr", chunkKeyStr);
          console.log("index", index);
          try {
            const chunk = await BigMap.get(
              Array.from(encoder.encode(chunkKeyStr))
            );
            console.log("chunk", chunk);
            chunkBuffers[index] = Buffer.from(new Uint8Array(chunk[0]));
            console.log("chunkBuffers", chunkBuffers);
          } catch (e) {
            console.error(`Error loading chunks: ${e}`);
          }
        })
      );
    } catch (e) {
      console.error(`Error loading chunks: ${e}`);
    }

    blobImage = URL.createObjectURL(
      new Blob([Buffer.concat(chunkBuffers, bufferSize)], {
        type: metadata.type,
      })
    );
    console.log("result", blobImage);
    return blobImage;
  }
</script>

<Row>
  <Col class="d-flex justify-content-center">
    <h1>Picture</h1>
  </Col>
</Row>
<Row>
  <form on:submit|preventDefault={handleSubmit}>
    <FormGroup>
      <input type="file" bind:files />

      {#if files && files[0]}
        <p>{files[0].name}</p>
      {/if}
    </FormGroup>
    <Button primary type="submit">Submit</Button>
  </form>
</Row>
<Row>
  <form on:submit|preventDefault={getFile}>
    <FormGroup><input bind:value={fileId} /></FormGroup>
    <Button primary type="submit">Submit</Button>
  </form>
</Row>
<Row><img src={blobImage} alt="." /></Row>