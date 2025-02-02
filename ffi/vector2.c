#include <stdbool.h>
#include <stdlib.h>
#include <assert.h>

typedef struct Vector2 Vector2;
typedef struct Vector2State Vector2State;
typedef struct Vector2Handle Vector2Handle;

struct Vector2 {
  double x, y;
  int id;
  int index;
};

struct Vector2State {
  bool closing;
  int id_ptr;
  int stack_ptr;
  int *free_ids;
  int *generation;
  Vector2 *vec2_pool;
  Vector2 **ptr_pool;
};

struct Vector2Handle {
  int id;
  int generation;
  Vector2State *state;
};

Vector2State* init(int size) {
  Vector2State *state = malloc(sizeof(Vector2State));
  state->vec2_pool = malloc(size * sizeof(Vector2));
  state->ptr_pool = malloc(size * sizeof(Vector2*));
  state->free_ids = malloc(size * sizeof(int));
  state->generation = malloc(size * sizeof(int));
  state->stack_ptr = 0;
  state->id_ptr = size;
  state->closing = false;

  for (int i = 0; i < size; i++) {
    state->vec2_pool[i].x = 0;
    state->vec2_pool[i].y = 0;
    state->vec2_pool[i].id = -1;
    state->vec2_pool[i].index = i;
    state->free_ids[i] = i;
    state->generation[i] = 0;
  }

  return state;
}

void close(Vector2State *state) {
  free(state->vec2_pool);
  free(state->ptr_pool);
  free(state->free_ids);
  free(state->generation);
  free(state);
}

void requestClose(Vector2State *state) {
  if (state->stack_ptr == 0) {
    close(state);
  } else {
    state->closing = true;
  }
}

Vector2Handle allocate(Vector2State *state, double x, double y) {
  assert(state->id_ptr > 0);

  Vector2Handle handle;
  int id = state->free_ids[--state->id_ptr];
  handle.id = id;
  handle.generation = state->generation[id];
  handle.state = state;

  int index = state->stack_ptr++;
  Vector2 *vec2 = &state->vec2_pool[index];
  vec2->x = x;
  vec2->y = y;
  vec2->id = id;
  vec2->index = index;

  state->ptr_pool[id] = vec2;

  return handle;
}

void release(Vector2Handle *h) {
  Vector2State *state = h->state;
  assert(h->generation == h->state->generation[h->id]);

  int index = state->ptr_pool[h->id]->index;
  int top = --state->stack_ptr;

  if (index != top) {
    Vector2 *occupant = &state->vec2_pool[top];
    state->vec2_pool[index] = *occupant;
    state->vec2_pool[index].index = index;
    state->ptr_pool[occupant->id] = &state->vec2_pool[index];
  }
  state->vec2_pool[top].id = -1;
  state->generation[h->id]++;
  state->free_ids[state->id_ptr++] = h->id;

  if (state->closing == true && state->stack_ptr == 0) {
    close(state);
  }
}
