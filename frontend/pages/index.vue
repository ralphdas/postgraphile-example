<template>
  <div>
    <posts-overview />
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import PostsOverview from '~/components/posts-overview.vue'

export default Vue.extend({
  components: {
    PostsOverview
  }
})
</script>
