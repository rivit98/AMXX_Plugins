#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>

#include "stack.h"

static void stack_grow(stack_t *stack, size_t howmuch);

static void stack_grow(stack_t *stack, size_t howmuch)
{
	stack->size+=howmuch;
	
	stack->head=(int **)realloc(stack->head,(stack->size)*sizeof(int *));
}
/**
 * Creates a basic stack.
 *
 * @param size		Size of the initial stack before needing to realloc with 32-pointer large chunks.
 * @return			Pointer to the stack.
 */
stack_t *stack_create(size_t size)
{
	stack_t *ret;		/**< Stack to return. */
	
	ret=malloc(sizeof(stack_t));
	
	memset(ret,0x0,sizeof(stack_t));
	
	ret->size=size;
	ret->head=(int **)malloc(size*sizeof(int *));
	
	return ret;
}

/**
 * Destroy the given stack.
 *
 * @param stack		The parameter to destroy.
 * @noreturn
 */
void stack_destroy(stack_t *stack)
{
	free(stack->head);
	
	free(stack);
}

/**
 * Destroy the given stack, and free each element.  Calls the dtor function for each element.
 *
 * @param stack			The stack to destroy.
 * @noreturn
 */
void stack_destroy_and_free(stack_t *stack, void (*dtor)(void *))
{
	void *cur;
	
	while (stack->pos > 0)
	{
		stack->pos--;
		
		cur=stack->head[stack->pos];
		
		if (dtor!=NULL)
		{
			dtor(cur);
		}
		
		free(cur);
	}
	
	free(stack->head);
	
	free(stack);
}
/**
 * Push data onto the stack.
 *
 * @param stack		The stack to push onto.
 * @param data		The data to push.
 * @noreturn
 */
void stack_push(stack_t *stack, void *data)
{
	if (stack->pos>=stack->size)
	{
		stack_grow(stack,32);
	}
	stack->head[stack->pos++]=data;
}
/**
 * Pop data off of the stack.
 *
 * @param stack		Stack to pop from.
 * @return			The data that was on the stack.
 */
void *stack_pop(stack_t *stack)
{
	if (stack->pos == 0)
	{
		return NULL;
	}
	
	return stack->head[--(stack->pos)];
}
/**
 * Tell what the head of the stack is like. Does not pop.
 *
 * @param stack		Stack to peek at.
 * @return			Data at head of the stack.
 */
void *stack_peek(stack_t *stack)
{
	if (stack->pos == 0)
	{
		return NULL;
	}
	
	return stack->head[stack->pos-1];
}
/**
 * Iterate the stack (from top of the stack to the bottom) calling the callback with the data and match.
 * Return 1 in the callback to stop the iteration (and ultimately return the data from this function)
 *
 * @param stack		The stack to iterate.
 * @param callback	The callback function to check.
 * @param match		The match data (sent to callback).
 * @return 			The matching stack item.
 */
void *stack_iterate(stack_t *stack, int (*callback)(void *,void *), void *match)
{
	int found=0;
	int pos=stack->pos;
	
	while (pos--)
	{
		if (callback(stack->head[pos],match))
		{
			found=1;
			break;
		}
	}
	if (found)
	{
		return stack->head[pos];
	}
	
	return NULL;
}
/**
 * Allocates a new stack and copies the data to it.
 *
 * @param stack		The stack to copy.
 * @return			Pointer to the new stack.
 */
stack_t *stack_copy(stack_t *stack)
{
	stack_t *ret;
	int **head;
	
	/* Allocate memory */
	ret=stack_create(stack->size);
	
	head=ret->head;
	
	memcpy(ret,stack,sizeof(stack_t));
	
	ret->head=head;
	

	/* Copy stack data */
	memcpy(ret->head,stack->head,stack->size*sizeof(int *));
	
	return ret;
}

/**
 * Reverse the order of the data in the stack.
 *
 * @param stack		The stack to flip.
 * @noreturn
 */
void stack_reverse(stack_t *stack)
{
	stack_t *n;
	
	n=stack_copy(stack);
	
	stack->pos=0;
	
	while (!stack_isempty(n))
	{
		stack_push(stack,stack_pop(n));
	}
	
	stack_destroy(n);
}
