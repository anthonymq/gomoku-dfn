<script>
  import { onMount } from "svelte";

  onMount(() => {});
  function placePawn() {
    console.log("LOL");
  }
</script>

<style>
  svg {
    width: 100%;
    height: 100%;
  }
  .board {
    stroke: #333;
  }
</style>

<svg viewBox="0 0 160 160">
  {#each Array(16) as _, i}
    <line
      stroke-width="0.5"
      class="board"
      y1={5 + i * 10}
      y2={5 + i * 10}
      x1="5"
      x2="155" />
    <line
      stroke-width="0.5"
      class="board"
      y1="5"
      y2="155"
      x1={5 + i * 10}
      x2={5 + i * 10} />
    {#each Array(16) as _, j}
      <circle
        id={i+"-"+j}
        cx={5 + i * 10}
        cy={5 + j * 10}
        r="2"
        stroke="black"
        stroke-width="0.5"
        fill="black"
        on:click={placePawn}
        on:mouseover={el => console.log(el)} 
        />
    {/each}
  {/each}
</svg>
