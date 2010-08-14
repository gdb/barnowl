#include "owl.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlite3.h>

#define SQLITE_DATABASE                   "barnowl.sql"
#define SQLITE_OK                         0
sqlite3 *db;

static int load_message(void* arg1, int cols, char** vals, char**keys) {
  int i;
  int maxid = 0;
  owl_message *msg = malloc(sizeof(owl_message));
  owl_messagelist *ml = arg1;
  owl_message_init(msg);
  for (i = 0; i < cols; i++) {
    if (strcmp("id", keys[i]) == 0) {
      msg->id = atoi(vals[i]);
      if (msg->id > maxid)
	maxid = msg->id;
    } else if (strcmp("isprivate", keys[i]) == 0) {
      if (atoi(vals[i]))
	owl_message_set_isprivate(msg);
    } else if (strcmp("pseudo", keys[i]) == 0) {
      if (atoi(vals[i]))
	owl_message_set_attribute(msg, "pseudo", "true");
    } else {
      owl_message_set_attribute(msg, keys[i], vals[i]);
    }
  }

  if (maxid)
    owl_global_set_nextmsgid(&g, maxid);

  owl_list_append_element(&(ml->list), msg);
  return 0;
}

static void load_messages(owl_messagelist *ml) {
  sqlite3_exec(db, "SELECT * FROM messages", load_message, ml, 0);
}

static void open_db(owl_messagelist *ml) {
  if (db == NULL) {
    sqlite3_open(SQLITE_DATABASE, &db);
    char create_table[1000] = "CREATE TABLE IF NOT EXISTS messages\n"
      "(id INT PRIMARY KEY,\n"
      "class TEXT,\n"
      "instance TEXT,\n"
      "sender TEXT,\n"
      "zsig TEXT,\n"
      "recipient TEXT,\n"
      "realm TEXT,\n"
      "body TEXT,\n"
      "opcode TEXT,\n"
      "isprivate TINYINT,\n"
      "type TEXT,\n"
      "pseudo INT,\n"
      "zwriteline TEXT)";
    if (sqlite3_exec(db, create_table, 0, 0, 0)) {
      printf("Problem: %s", sqlite3_errmsg(db));
      exit(1);
    }
    load_messages(ml);
  }
}

int owl_messagelist_create(owl_messagelist *ml)
{
  owl_list_create(&(ml->list));
  open_db(ml);
  return(0);
}

int owl_messagelist_get_size(const owl_messagelist *ml)
{
  return(owl_list_get_size(&(ml->list)));
}

void *owl_messagelist_get_element(const owl_messagelist *ml, int n)
{
  return(owl_list_get_element(&(ml->list), n));
}

owl_message *owl_messagelist_get_by_id(const owl_messagelist *ml, int target_id)
{
  /* return the message with id == 'id'.  If it doesn't exist return NULL. */
  int first, last, mid, msg_id;
  owl_message *m;

  first = 0;
  last = owl_list_get_size(&(ml->list)) - 1;
  while (first <= last) {
    mid = (first + last) / 2;
    m = owl_list_get_element(&(ml->list), mid);
    msg_id = owl_message_get_id(m);
    if (msg_id == target_id) {
      return(m);
    } else if (msg_id < target_id) {
      first = mid + 1;
    } else {
      last = mid - 1;
    }
  }
  return(NULL);
}

int owl_messagelist_append_element(owl_messagelist *ml, void *element)
{
  /* Missing: hostname.  Some others: id, class, instance, sender, zsig,
     recipient, realm, body, opcode, loginout, isprivate, type, pseudo,
     zwriteline, question */
  char *query = sqlite3_mprintf("INSERT INTO messages (id, class, instance, sender,\n"
				"zsig, recipient, realm, body, opcode,\n"
				"isprivate, type, pseudo, zwriteline) VALUES\n"
				"(%d, %Q, %Q, %Q,\n"
				"%Q, %Q, %Q, %Q, %Q,\n"
				"%d, %Q, %d, %Q)",
				owl_message_get_id(element),
				owl_message_get_class(element),
				owl_message_get_instance(element),
				owl_message_get_sender(element),

				owl_message_get_zsig(element),
				owl_message_get_recipient(element),
				owl_message_get_realm(element),
				owl_message_get_body(element),
				owl_message_get_opcode(element),

				owl_message_is_private(element),
				owl_message_get_type(element),
				owl_message_is_pseudo(element),
				owl_message_get_zwriteline(element));
  int res = sqlite3_exec(db, query, 0, 0, 0);
  sqlite3_free(query);
  return(owl_list_append_element(&(ml->list), element));
}

/* do we really still want this? */
int owl_messagelist_delete_element(owl_messagelist *ml, int n)
{
  /* mark a message as deleted */
  owl_message_mark_delete(owl_list_get_element(&(ml->list), n));
  return(0);
}

int owl_messagelist_undelete_element(owl_messagelist *ml, int n)
{
  /* mark a message as deleted */
  owl_message_unmark_delete(owl_list_get_element(&(ml->list), n));
  return(0);
}

int owl_messagelist_expunge(owl_messagelist *ml)
{
  /* expunge deleted messages */
  int i, j;
  owl_list newlist;
  owl_message *m;

  owl_list_create(&newlist);
  /*create a new list without messages marked as deleted */
  j=owl_list_get_size(&(ml->list));
  for (i=0; i<j; i++) {
    m=owl_list_get_element(&(ml->list), i);
    if (owl_message_is_delete(m)) {
      owl_message_delete(m);
    } else {
      owl_list_append_element(&newlist, m);
    }
  }

  /* free the old list */
  owl_list_cleanup(&(ml->list), NULL);

  /* copy the new list to the old list */
  ml->list = newlist;

  return(0);
}

void owl_messagelist_invalidate_formats(const owl_messagelist *ml)
{
  int i, j;
  owl_message *m;

  j=owl_list_get_size(&(ml->list));
  for (i=0; i<j; i++) {
    m=owl_list_get_element(&(ml->list), i);
    owl_message_invalidate_format(m);
  }
}
