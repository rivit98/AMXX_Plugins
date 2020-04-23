#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>

#include "list.h"

/**
 * Creates and initializes a list.
 *
 * @return			Pointer to the new list.
 */
list_t *list_create(void)
{
	list_t *ret;	/**< The list to return. */
	
	ret=malloc(sizeof(list_t));
	
	list_initialize(ret);
	
	return ret;
}
/**
 * Initializes the linked list by creating a sentinel node.
 *
 * @param list		The list pointer to initialize.
 */
void list_initialize(list_t *list)
{
	list_element_t	*sentinel;	/**< The sentinel node. */
	
	sentinel=malloc(sizeof(list_element_t));
	
	sentinel->issentinel=1;
	sentinel->data=NULL;
	
	sentinel->next=sentinel;
	sentinel->prev=sentinel;
	
	list->first=sentinel;
	list->last=sentinel;
	
	list->size=0;
}

/**
 * Destroys the list, does not free() the elements actual data.  Frees the list structure itself, too.
 *
 * @param list		The list pointer to destroy.
 */
void list_destroy(list_t *list)
{
	
	list_element_t		*current;
	list_element_t		*next;
	
	current=list->first;
	
	current=current->next;
	
	/* Clean up all of the non-sentinel nodes.  Start at first->next */
	while (current->issentinel==0)
	{
		/* Save down the next pointer since this node will be freed. */
		next=current->next;
		
		/* Free the node */
		free(current);
		
		/* Move on. */
		current=next;
	}
	
	/* Current now points to the sentinel node. */
	free(current);
	
	free(list);
}
/**
 * Destroys the list, does free() the elements actual data.  Frees the list structure itself, too.
 *
 * @param dtor		The optional destructor to call right before the data is freed.
 * @param list		The list pointer to destroy.
 */
void list_destroy_and_free(list_t *list, void (*dtor)(void *))
{
	
	list_element_t		*current;
	list_element_t		*next;
	
	current=list->first;
	
	current=current->next;
	
	/* Clean up all of the non-sentinel nodes.  Start at first->next */
	while (current->issentinel==0)
	{
		/* Save down the next pointer since this node will be freed. */
		next=current->next;
		
		if (dtor!=NULL)
		{
			dtor(current->data);
		}
		/* Free the node's data. */
		free(current->data);
		
		/* Free the node */
		free(current);
		
		/* Move on. */
		current=next;
	}
	
	/* Current now points to the sentinel node. */
	free(current);
	
	free(list);
}
/**
 * Creates a new element and adds it into the list.
 *
 * @param data		The data to add to the element.
 * @param list		The list to add this to.
 */
void list_add(void *data, list_t *list)
{
	list_element_t		*element;		/**< The element that is created. */
	
	element=list_create_element(data);
	
	list_insert(list,element);
}
/**
 * Creates an element with the given data.
 *
 * @param data		The data to put into this element.
 * @return			Pointer to the new element.
 */
list_element_t *list_create_element(void *data)
{
	list_element_t		*ret;		/**< The element to return. */
	
	ret=malloc(sizeof(list_element_t));
	
	memset(ret,0x0,sizeof(list_element_t));
	ret->data=data;
	
	return ret;
}

/**
 * Inserts the element into the back of the list.
 *
 * @param list		List that gets the element.
 * @param element	Element that goes into the list.
 */
void list_insert(list_t *list, list_element_t *element)
{
	list_element_t		*last;	/**< The previous "last" value of the list. */
	list_element_t		*next;	/**< The previous "last" value of the list's next field. */
	
	last=list->last;
	next=last->next;
	
	list->last=element;
	last->next=element;
	
	next->prev=element;
	
	element->prev=last;
	element->next=next;
}

/**
 * Iterates the list internally and calls the callback function with the data.
 * If the callback function returns a 1, then stop iteration.
 *
 * @param list		The list to iterate.
 * @param callback	The callback function.
 * @param match		The extra parameter passed to the callback for match, cast to void.
 */
void *list_iterate(list_t *list, int (*callback)(void *,void *), void *match)
{
	list_element_t		*current;
	
	current=list->first;
	
	current=current->next; /* Skip past the sentinel. */
	
	/* Clean up all of the non-sentinel nodes.  Start at first->next */
	while (current->issentinel==0)
	{
		if (callback(current->data,match)==1)
		{
			/* Was found. */
			return current->data;
		}
		/* Move on. */
		current=current->next;
	}
	
	/* Was not found. */
	return NULL;
}
 
