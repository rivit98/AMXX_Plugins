#if !defined(STACK_H)
#define STACK_H

typedef struct stack_s
{
	size_t				  size;		/**< Size of the stack (in void * pointers) */
	unsigned int		  pos;		/**< Position in the stack. */
	int					**head;		/**< Pointer to the head (cast to int * for compiler warning prevention) */
} stack_t;

#if defined(__cplusplus)
extern "C"
{
#endif

/* NOTE: pop does NOT free anything */
stack_t	*stack_create(size_t size);
void	 stack_destroy(stack_t *stack);
void	 stack_destroy_and_free(stack_t *stack, void (*dtor)(void *));
void	 stack_push(stack_t *stack, void *data);
void	*stack_pop(stack_t *stack);
void	*stack_peek(stack_t *stack);
void	*stack_iterate(stack_t *stack, int (*callback)(void *,void *), void *match);
stack_t	*stack_copy(stack_t *stack);
void	 stack_reverse(stack_t *stack);

#define stack_isempty(___STACK)		( ( (___STACK) ->pos)==0)
#define stack_entries(___STACK)		( ( ( ___STACK )->pos ) )
#define stack_pop_safe(___STACK)	( (stack_isempty((___STACK))) ? ( ___STACK )->head[0] : stack_pop((___STACK)) )
#if defined __cplusplus
};
#endif
#endif
