#if !defined(LIST_H)
#define LIST_H

typedef struct list_element_s
{
	void						*data;
	int							 issentinel;
	struct list_element_s		*next;
	struct list_element_s		*prev;
} list_element_t;

typedef struct list_s
{
	size_t				 size;
	list_element_t		*first;
	list_element_t		*last;
} list_t;

#if defined(__cplusplus)
extern "C"
{
#endif

list_t *list_create(void);
void list_initialize(list_t *list);
void list_destroy(list_t *list);
void list_destroy_and_free(list_t *list, void (*dtor)(void *));
void list_add(void *data, list_t *list);
list_element_t *list_create_element(void *data);
void list_insert(list_t *list, list_element_t *element);
void *list_iterate(list_t *list, int (*callback)(void *,void *), void *match);
#if defined __cplusplus
};
#endif
#endif
