%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


-module (ms_os_api).


-export ([
		object_create/1, object_create/6, object_create/7, object_create/2,
		object_create_data/2, object_create_data/3, object_create_data/4,
		object_destroy/1, object_destroy/2,
		object_select/1, object_select/2,
		object_update/1, object_update/6, object_update/7, object_update/2,
		object_update_data/2, object_update_data/3, object_update_data/4,
		object_patch/2,
		objects_select/1, objects_select/2]).


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


-import (ve_enforcements, [enforce_ok_1/1]).


-include ("ms_os_coders.hrl").


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


object_create (Object) ->
	case ms_os_coders:coerce_object (Object) of
		{ok, Object_1} ->
			call (object_create, Object_1);
		Error = {error, _} ->
			Error
	end.


object_create (Key, Data, Indices, Links, Attachments, Annotations) ->
	object_create ({Key, Data, Indices, Links, Attachments, Annotations}).

object_create (Collection, Object, Data, Indices, Links, Attachments, Annotations) ->
	object_create ({Collection, Object}, Data, Indices, Links, Attachments, Annotations).


object_create (Key, Object) ->
	case ms_os_coders:coerce_object_with_key (Key, Object) of
		{ok, Object_1} ->
			call (object_create, Object_1);
		Error = {error, _} ->
			Error
	end.


%----------------------------------------------------------------------------


object_create_data (Key, Data) ->
	object_create (Key, Data, none, none, none, none).

object_create_data (Key, DataType, DataData) ->
	object_create_data (Key, {DataType, DataData}).

object_create_data (Collection, Object, DataType, DataData) ->
	object_create_data ({Collection, Object}, {DataType, DataData}).


%----------------------------------------------------------------------------


object_destroy (Key) ->
	case ms_os_coders:coerce_object_key (Key) of
		{ok, Key_1} ->
			call (object_destroy, Key_1);
		Error = {error, _} ->
			Error
	end.


object_destroy (Collection, Object) ->
	object_destroy ({Collection, Object}).


%----------------------------------------------------------------------------


object_select (Key) ->
	case ms_os_coders:coerce_object_key (Key) of
		{ok, Key_1} ->
			call (object_select, Key_1);
		Error = {error, _} ->
			Error
	end.


object_select (Collection, Object) ->
	object_select ({Collection, Object}).


%----------------------------------------------------------------------------


object_update (Object) ->
	case ms_os_coders:coerce_object (Object) of
		{ok, Object_1} ->
			call (object_update, Object_1);
		Error = {error, _} ->
			Error
	end.


object_update (Key, Data, Indices, Links, Attachments, Annotations) ->
	object_update ({Key, Data, Indices, Links, Attachments, Annotations}).

object_update (Collection, Object, Data, Indices, Links, Attachments, Annotations) ->
	object_update ({Collection, Object}, Data, Indices, Links, Attachments, Annotations).


object_update (Key, Object) ->
	case ms_os_coders:coerce_object_with_key (Key, Object) of
		{ok, Object_1} ->
			call (object_update, Object_1);
		Error = {error, _} ->
			Error
	end.


%----------------------------------------------------------------------------


object_update_data (Key, Data) ->
	object_patch (Key, {data, update, Data}).

object_update_data (Key, DataType, DataData) ->
	object_update_data (Key, {DataType, DataData}).

object_update_data (Collection, Object, DataType, DataData) ->
	object_update_data ({Collection, Object}, {DataType, DataData}).


%----------------------------------------------------------------------------


object_patch (Key, Patch) ->
	case ms_os_coders:coerce_object_key (Key) of
		{ok, Key_1} ->
			case ms_os_coders:coerce_object_patch (Patch) of
				{ok, Patch_1} ->
					call (object_patch, {Key_1, Patch_1});
				Error = {error, _} ->
					Error
			end;
		Error = {error, _} ->
			Error
	end.


%----------------------------------------------------------------------------


objects_select (Selector, Mangler) ->
	case ms_os_coders:coerce_object_selector (Selector) of
		{ok, Selector_1} ->
			case ms_os_coders:coerce_object_mangler (Mangler) of
				{ok, Mangler_1} ->
					call (objects_select, Selector_1, Mangler_1);
				Error = {error, _} ->
					Error
			end;
		Error = {error, _} ->
			Error
	end.


objects_select (Selector) ->
	objects_select (Selector, object).


%----------------------------------------------------------------------------


call (Operation, Argument) ->
	ms_os_backend:call (Operation, Argument).

call (Operation, Argument_1, Argument_2) ->
	ms_os_backend:call (Operation, {Argument_1, Argument_2}).


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------
