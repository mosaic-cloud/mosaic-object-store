%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


-module (ms_os_coders).


-export ([
		merge_object/2,
		patch_object/2,
		match_object/2,
		mangle_object/2]).

-export ([
		coerce_object/6, coerce_object/7, coerce_object/1, coerce_object/2, coerce_objects/1, coerce_objects/2, coerce_object_with_key/2,
		coerce_object_key/2, coerce_object_key/1, coerce_object_keys/1,
		coerce_object_data/2, coerce_object_data/1,
		coerce_object_index/2, coerce_object_index/1, coerce_object_indices/1,
		coerce_object_link/2, coerce_object_link/1, coerce_object_links/1,
		coerce_object_attachment/5, coerce_object_attachment/1, coerce_object_attachments/1,
		coerce_object_annotation/2, coerce_object_annotation/1,
		coerce_data/2, coerce_data/1,
		coerce_attachment/5, coerce_attachment/6, coerce_attachment/1, coerce_attachment/2, coerce_attachments/1, coerce_attachments/2,
		coerce_annotation/2, coerce_annotation/1, coerce_annotations/1,
		coerce_identifier/1,
		coerce_content_type/1,
		coerce_fingerprint/1,
		coerce_value/1, coerce_values/1,
		coerce_object_patch/1,
		coerce_object_selector/1,
		coerce_object_mangler/1]).

-export ([
		validate_object/1, validate_object/2,
		validate_object_key/1,
		validate_object_data/1,
		validate_object_index/1, validate_object_indices/1,
		validate_object_link/1, validate_object_links/1,
		validate_object_attachment/1, validate_object_attachments/1,
		validate_data/1,
		validate_attachment/1,
		validate_annotation/1, validate_annotations/1,
		validate_identifier/1,
		validate_content_type/1,
		validate_fingerprint/1,
		validate_object_patch/1,
		validate_object_selector/1,
		validate_object_mangler/1]).

-export ([
		decode_json_object/1, decode_json_object/2, decode_json_objects/1,
		decode_json_object_key/1,
		decode_json_object_data/1,
		decode_json_object_indices/1, decode_json_object_index_values/1, decode_json_object_index_value/1,
		decode_json_object_links/1, decode_json_object_link_references/1, decode_json_object_link_reference/1,
		decode_json_object_attachments/1, decode_json_object_attachment/1,
		decode_json_object_annotations/1, decode_json_object_annotation_value/1,
		decode_json_data/1,
		decode_json_attachment/1,
		decode_json_annotations/1, decode_json_annotation_value/1,
		decode_json_identifier/1, decode_json_identifiers/1,
		decode_json_content_type/1,
		decode_json_fingerprint/1]).

-export ([
		encode_json_object/1, encode_json_object/2, encode_json_objects/1,
		encode_json_object_key/1,
		encode_json_object_data/1,
		encode_json_object_indices/1, encode_json_object_index_values/1, encode_json_object_index_value/1,
		encode_json_object_links/1, encode_json_object_link_references/1, encode_json_object_link_reference/1,
		encode_json_object_attachments/1, encode_json_object_attachment/1,
		encode_json_object_annotations/1, encode_json_object_annotation_value/1,
		encode_json_data/1,
		encode_json_attachment/1,
		encode_json_annotations/1, encode_json_annotation_value/1,
		encode_json_identifier/1, encode_json_identifiers/1,
		encode_json_content_type/1,
		encode_json_fingerprint/1]).

-export ([
		encode_binary_data/1]).

-export ([
		schema_term/1,
		schema_json/1]).


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


-import (ve_enforcements, [enforce_ok_1/1, enforce_ok_2/1, enforce_ok_map/2]).


-include ("ms_os_coders.hrl").


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


merge_object (Object = #ms_os_object_v1{}, none) ->
	merge_object (Object, simplify);
	
merge_object (Object = #ms_os_object_v1{}, simplify) ->
	coerce_object (Object);
	
merge_object (NewObject = #ms_os_object_v1{}, _OldObject = #ms_os_object_v1{}) ->
	merge_object (NewObject, simplify).


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


patch_object (Patch, Object) ->
	try
		{ok, patch_object_ok (Patch, Object)}
	catch
		throw : {error, Reason} -> {error, Reason};
		throw : Reason -> {error, {invalid_object_patch, Patch, {unexpected_error, Reason, erlang:get_stacktrace ()}}};
		error : Reason -> {error, {invalid_object_patch, Patch, {unexpected_error, Reason, erlang:get_stacktrace ()}}};
		exit : Reason -> {error, {invalid_object_patch, Patch, {unexpected_error, Reason, erlang:get_stacktrace ()}}}
	end.


patch_object_ok ({data, exclude}, Object) ->
	Object#ms_os_object_v1{data = none};
	
patch_object_ok ({data, update, Data}, Object) ->
	Object#ms_os_object_v1{data = Data};
	
	% ----------------------------------------
	
patch_object_ok ({indices_all, exclude}, Object) ->
	Object#ms_os_object_v1{indices = []};
	
patch_object_ok ({indices_all, update, Indices}, Object) ->
	Object#ms_os_object_v1{indices = Indices};
	
patch_object_ok ({indices_each, Operation, Indices}, Object)
			when (Operation =:= update); (Operation =:= include); (Operation =:= exclude) ->
	Object#ms_os_object_v1{indices = patch_records_ok (Operation, Indices, Object#ms_os_object_v1.indices)};
	
patch_object_ok ({index_values, update, Index, Values}, Object) ->
	patch_object_ok ({indices_each, update, [#ms_os_object_index_v1{key = Index, values = Values}]}, Object);
	
patch_object_ok ({index_values, Operation, Index_, Values}, Object)
			when (Operation =:= include); (Operation =:= exclude) ->
	Transformer = fun (Index) ->
		Index#ms_os_object_index_v1{values = patch_values_ok (Operation, Values, Index#ms_os_object_index_v1.values)}
	end,
	Object#ms_os_object_v1{indices = patch_records_ok ({transform, Transformer}, [Index_], Object#ms_os_object_v1.indices)};
	
	% ----------------------------------------
	
patch_object_ok ({links_all, exclude}, Object) ->
	Object#ms_os_object_v1{links = []};
	
patch_object_ok ({links_all, update, Links}, Object) ->
	Object#ms_os_object_v1{links = Links};
	
patch_object_ok ({links_each, Operation, Links}, Object)
			when (Operation =:= update); (Operation =:= include); (Operation =:= exclude) ->
	Object#ms_os_object_v1{links = patch_records_ok (Operation, Links, Object#ms_os_object_v1.links)};
	
patch_object_ok ({link_references, update, Link, References}, Object) ->
	patch_object_ok ({links_each, update, [#ms_os_object_link_v1{key = Link, references = References}]}, Object);
	
patch_object_ok ({link_references, Operation, Link_, Values}, Object)
			when (Operation =:= include); (Operation =:= exclude) ->
	Transformer = fun (Link) ->
		Link#ms_os_object_link_v1{references = patch_values_ok (Operation, Values, Link#ms_os_object_link_v1.references)}
	end,
	Object#ms_os_object_v1{links = patch_records_ok ({transform, Transformer}, [Link_], Object#ms_os_object_v1.links)};
	
	% ----------------------------------------
	
patch_object_ok ({attachments_all, exclude}, Object) ->
	Object#ms_os_object_v1{attachments = []};
	
patch_object_ok ({attachments_all, update, Attachments}, Object) ->
	Object#ms_os_object_v1{attachments = Attachments};
	
patch_object_ok ({attachments_each, Operation, Attachments}, Object)
			when (Operation =:= update); (Operation =:= include); (Operation =:= exclude) ->
	Object#ms_os_object_v1{attachments = patch_records_ok (Operation, Attachments, Object#ms_os_object_v1.attachments)};
	
	% ----------------------------------------
	
patch_object_ok ({annotations_all, exclude}, Object) ->
	Object#ms_os_object_v1{annotations = []};
	
patch_object_ok ({annotations_all, update, Annotations}, Object) ->
	Object#ms_os_object_v1{annotations = Annotations};
	
patch_object_ok ({annotations_each, Operation, Annotations}, Object)
			when (Operation =:= update); (Operation =:= include); (Operation =:= exclude) ->
	Object#ms_os_object_v1{annotations = patch_records_ok (Operation, Annotations, Object#ms_os_object_v1.annotations)};
	
	% ----------------------------------------
	
patch_object_ok ({patches, Patches}, Object) ->
	lists:foldl (fun patch_object_ok/2, Object, Patches);
	
	% ----------------------------------------
	
patch_object_ok (Patch, _Object) ->
	throw ({error, {invalid_object_patch, Patch}}).


patch_records_ok (update, NewRecords, OldRecords) ->
	lists:foldl (
			fun (NewRecord, CurrentRecords) ->
				case lists:keytake (element (2, NewRecord), 2, CurrentRecords) of
					{value, _OldRecord, CurrentRecords_2} ->
						[NewRecord | CurrentRecords_2];
					false ->
						throw ({error, {missing, element (2, NewRecord)}})
				end
			end,
			OldRecords, NewRecords);
	
patch_records_ok (include, NewRecords, OldRecords) ->
	lists:foldl (
			fun (NewRecord, CurrentRecords) ->
				case lists:keysearch (element (2, NewRecord), 2, CurrentRecords) of
					{value, _OldRecord} ->
						throw ({error, {existing, element (2, NewRecord)}});
					false ->
						[NewRecord | CurrentRecords]
				end
			end,
			OldRecords, NewRecords);
	
patch_records_ok (exclude, NewRecords, OldRecords) ->
	lists:foldl (
			fun (NewRecord, CurrentRecords) ->
				case lists:keytake (NewRecord, 2, CurrentRecords) of
					{value, _OldRecord, CurrentRecords_2} ->
						CurrentRecords_2;
					false ->
						throw ({error, {missing, NewRecord}})
				end
			end,
			OldRecords, NewRecords);
	
patch_records_ok ({transform, Transformer}, NewRecords, OldRecords) ->
	lists:foldl (
			fun (NewRecord, CurrentRecords) ->
				case lists:keytake (NewRecord, 2, CurrentRecords) of
					{value, OldRecord, CurrentRecords_2} ->
						[Transformer (OldRecord) | CurrentRecords_2];
					false ->
						throw ({error, {missing, NewRecord}})
				end
			end,
			OldRecords, NewRecords).


patch_values_ok (include, NewValues, OldValues) ->
	lists:foldl (
			fun (NewValue, CurrentValues) ->
				case lists_take (NewValue, CurrentValues) of
					{value, _} ->
						throw ({error, {exsting, NewValue}});
					false ->
						[NewValue, CurrentValues]
				end
			end,
			OldValues, NewValues);
	
patch_values_ok (exclude, NewValues, OldValues) ->
	lists:foldl (
			fun (NewValue, CurrentValues) ->
				case lists_take (NewValue, CurrentValues) of
					{value, CurrentValues_2} ->
						CurrentValues_2;
					false ->
						throw ({error, {missing, NewValue}})
				end
			end,
			OldValues, NewValues).


lists_take (Value, List) ->
	lists_take (Value, List, []).

lists_take (_, [], _) ->
	false;
	
lists_take (Value, [Value | List], Others) ->
	{value, List ++ Others};
	
lists_take (Value, [Other | List], Others) ->
	lists_take (Value, List, [Other | Others]).


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


match_object (any, _Object) ->
	{ok, true};
	
match_object ({key, Key}, Object) ->
	{ok, Key =:= Object#ms_os_object_v1.key};
	
match_object ({collection, Collection}, Object) ->
	{ok, Collection =:= (Object#ms_os_object_v1.key)#ms_os_object_key_v1.collection};
	
match_object ({index, Index, Selector}, Object) ->
	match_object_index (Index, Selector, Object);
	
match_object (Selector, _Object) ->
	{error, {invalid_object_selector, Selector}}.


match_object_index (Index, Selector, Object) ->
	case lists:keyfind (Index, 2, Object#ms_os_object_v1.indices) of
		false ->
			{ok, false};
		#ms_os_object_index_v1{values = Values} ->
			match_object_index_values (Selector, Values)
	end.

match_object_index_values (_Selector, []) ->
	{ok, false};
	
match_object_index_values (Selector, [Value | Values]) ->
	case match_object_index_value (Selector, Value) of
		Outcome = {ok, true} ->
			Outcome;
		{ok, false} ->
			match_object_index_values (Selector, Values);
		Error = {error, _} ->
			Error
	end.


match_object_index_value ({equals, ExpectedValue}, Value) ->
	{ok, ExpectedValue =:= Value};
	
match_object_index_value ({lesser, MaxValue, Inclusive}, Value) ->
	if
		Inclusive ->
			{ok, Value =< MaxValue};
		true ->
			{ok, Value < MaxValue}
	end;
	
match_object_index_value ({greater, MinValue, Inclusive}, Value) ->
	if
		Inclusive ->
			{ok, Value >= MinValue};
		true ->
			{ok, Value > MinValue}
	end;
	
match_object_index_value ({range, MinValue, MinValueInclusive, MaxValue, MaxValueInclusive}, Value) ->
	case match_object_index_value ({lesser, MaxValue, MaxValueInclusive}, Value) of
		{ok, true} ->
			case match_object_index_value ({greater, MinValue, MinValueInclusive}, Value) of
				Outcome = {ok, _} ->
					Outcome;
				Error = {error, _} ->
					Error
			end;
		Outcome = {ok, false} ->
			Outcome;
		Error = {error, _} ->
			Error
	end;
	
match_object_index_value (Selector, _Value) ->
	{error, {invalid_object_index_value_selector, Selector}}.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


mangle_object (object, Object) ->
	{ok, Object};
	
mangle_object (key, Object) ->
	{ok, Object#ms_os_object_v1.key};
	
mangle_object ({key, collection}, Object) ->
	{ok, (Object#ms_os_object_v1.key)#ms_os_object_key_v1.collection};
	
mangle_object ({key, object}, Object) ->
	{ok, (Object#ms_os_object_v1.key)#ms_os_object_key_v1.object};
	
mangle_object (Mangler, _) ->
	{error, {invalid_object_mangler, Mangler}}.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


coerce_object (Key, Data, Indices, Links, Attachments, Annotations) ->
	coerce_object (Key, Data, Indices, Links, Attachments, Annotations, true).

coerce_object (Key, Data, Indices, Links, Attachments, Annotations, WithKey)
			when is_boolean (WithKey) ->
	try
		Entity = #ms_os_object_v1{
				key = if
							WithKey -> enforce_ok_1 (coerce_object_key (Key));
							(Key =:= none) -> none;
							true -> throw ({error, {expected, none}})
						end,
				data = enforce_ok_1 (coerce_object_data (Data)),
				indices = enforce_ok_1 (coerce_object_indices (Indices)),
				links = enforce_ok_1 (coerce_object_links (Links)),
				attachments = enforce_ok_1 (coerce_object_attachments (Attachments)),
				annotations = enforce_ok_1 (coerce_object_annotations (Annotations))},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.


coerce_object (Entity) ->
	coerce_object (Entity, true).

coerce_object (Entity = #ms_os_object_v1{}, WithKey) ->
	coerce_object (
			Entity#ms_os_object_v1.key,
			Entity#ms_os_object_v1.data,
			Entity#ms_os_object_v1.indices,
			Entity#ms_os_object_v1.links,
			Entity#ms_os_object_v1.attachments,
			Entity#ms_os_object_v1.annotations,
			WithKey);
	
coerce_object ({Key, Data, Indices, Links, Attachments, Annotations}, WithKey) ->
	coerce_object (Key, Data, Indices, Links, Attachments, Annotations, WithKey).


coerce_objects (Entities) ->
	coerce_objects (Entities, true).

coerce_objects (Entities, WithKey)
			when is_list (Entities), is_boolean (WithKey) ->
	try
		{ok, enforce_ok_map (
				fun (Entity) ->
					coerce_object (Entity, WithKey)
				end, Entities)}
	catch throw : Error = {error, _} -> Error end.


coerce_object_with_key (Key, Object) ->
	case coerce_object (Object, false) of
		{ok, Object_1} ->
			case coerce_object_key (Key) of
				{ok, Key_1} ->
					{ok, Object_1#ms_os_object_v1{key = Key_1}};
				Error = {error, _} ->
					Error
			end;
		Error = {error, _} ->
			Error
	end.


%----------------------------------------------------------------------------


coerce_object_key (Collection, Object) ->
	try
		Entity = #ms_os_object_key_v1{
				collection = enforce_ok_1 (coerce_identifier (Collection)),
				object = enforce_ok_1 (coerce_identifier (Object))},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.


coerce_object_key (Entity = #ms_os_object_key_v1{}) ->
	coerce_object_key (
			Entity#ms_os_object_key_v1.collection,
			Entity#ms_os_object_key_v1.object);
			
coerce_object_key ({Collection, Object}) ->
	coerce_object_key (Collection, Object).


coerce_object_keys (Entities)
			when is_list (Entities) ->
	try
		{ok, enforce_ok_map (fun coerce_object_key/1, Entities)}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


coerce_object_data (Type, Data) ->
	coerce_data (Type, Data).


coerce_object_data (none) ->
	{ok, none};
	
coerce_object_data (Entity) ->
	coerce_data (Entity).


%----------------------------------------------------------------------------


coerce_object_index (Key, Values) ->
	try
		Entity = #ms_os_object_index_v1{
				key = enforce_ok_1 (coerce_identifier (Key)),
				values = enforce_ok_1 (coerce_object_index_values (Values))},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.


coerce_object_index (Entity = #ms_os_object_index_v1{}) ->
	coerce_object_index (
			Entity#ms_os_object_index_v1.key,
			Entity#ms_os_object_index_v1.values);
	
coerce_object_index ({Key, Values}) ->
	coerce_object_index (Key, Values).


coerce_object_indices (none) ->
	{ok, []};
	
coerce_object_indices (Entities)
			when is_list (Entities) ->
	try
		{ok, coerce_records_ok (enforce_ok_map (fun coerce_object_index/1, Entities))}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


coerce_object_index_value (Value) ->
	coerce_value (Value).


coerce_object_index_values (none) ->
	{ok, []};
	
coerce_object_index_values (Values)
			when is_list (Values) ->
	try
		{ok, coerce_values_ok (enforce_ok_map (fun coerce_object_index_value/1, Values))}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


coerce_object_link (Key, References) ->
	try
		Entity = #ms_os_object_link_v1{
				key = enforce_ok_1 (coerce_identifier (Key)),
				references = enforce_ok_1 (coerce_object_link_references (References))},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.


coerce_object_link (Entity = #ms_os_object_link_v1{}) ->
	coerce_object_link (
			Entity#ms_os_object_link_v1.key,
			Entity#ms_os_object_link_v1.references);
	
coerce_object_link ({Key, References}) ->
	coerce_object_link (Key, References).


coerce_object_links (none) ->
	{ok, []};
	
coerce_object_links (Entities)
			when is_list (Entities) ->
	try
		{ok, coerce_records_ok (enforce_ok_map (fun coerce_object_link/1, Entities))}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


coerce_object_link_reference (Entity) ->
	coerce_object_key (Entity).

coerce_object_link_references (none) ->
	{ok, []};
	
coerce_object_link_references (Entities)
			when is_list (Entities) ->
	try
		{ok, coerce_values_ok (enforce_ok_map (fun coerce_object_link_reference/1, Entities))}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


coerce_object_attachment (Key, Type, Size, Fingerprint, Annotations) ->
	coerce_attachment (Key, Type, Size, Fingerprint, Annotations).


coerce_object_attachment (Entity) ->
	coerce_attachment (Entity).


coerce_object_attachments (none) ->
	{ok, []};
	
coerce_object_attachments (Entities)
			when is_list (Entities) ->
	coerce_attachments (Entities).


%----------------------------------------------------------------------------


coerce_object_annotation (Key, Value) ->
	coerce_annotation (Key, Value).


coerce_object_annotation (Entity) ->
	coerce_annotation (Entity).


coerce_object_annotations (none) ->
	{ok, []};
	
coerce_object_annotations (Entities)
			when is_list (Entities) ->
	coerce_annotations (Entities).


%----------------------------------------------------------------------------


coerce_data (Type, Data) ->
	try
		Entity = #ms_os_data_v1{
				type = enforce_ok_1 (coerce_content_type (Type)),
				data = enforce_ok_1 (coerce_data_data (Data))},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.

coerce_data_data (Data) ->
	coerce_value (Data).


coerce_data (Entity = #ms_os_data_v1{}) ->
	coerce_data (
			Entity#ms_os_data_v1.type,
			Entity#ms_os_data_v1.data);
	
coerce_data ({Type, Data}) ->
	coerce_data (Type, Data).


%----------------------------------------------------------------------------


coerce_attachment (Key, Type, Size, Fingerprint, Annotations) ->
	coerce_attachment (Key, Type, Size, Fingerprint, Annotations, true).

coerce_attachment (Key, Type, Size, Fingerprint, Annotations, WithKey)
			when is_boolean (WithKey) ->
	try
		Entity = #ms_os_attachment_v1{
				key = if
							WithKey -> enforce_ok_1 (coerce_identifier (Key));
							(Key =:= none) -> none;
							true -> throw ({error, {expected, none}})
						end,
				type = enforce_ok_1 (coerce_content_type (Type)),
				size = enforce_ok_1 (coerce_term (Size, {integer, {positive, false}})),
				fingerprint = enforce_ok_1 (coerce_fingerprint (Fingerprint)),
				annotations = enforce_ok_1 (coerce_annotations (Annotations))},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.


coerce_attachment (Entity) ->
	coerce_attachment (Entity, true).

coerce_attachment (Entity = #ms_os_attachment_v1{}, WithKey) ->
	coerce_attachment (
			Entity#ms_os_attachment_v1.key,
			Entity#ms_os_attachment_v1.type,
			Entity#ms_os_attachment_v1.size,
			Entity#ms_os_attachment_v1.fingerprint,
			Entity#ms_os_attachment_v1.annotations,
			WithKey);
	
coerce_attachment ({Key, Type, Size, Fingerprint, Annotations}, WithKey) ->
	coerce_attachment (Key, Type, Size, Fingerprint, Annotations, WithKey).


coerce_attachments (Entities) ->
	coerce_attachments (Entities, true).

coerce_attachments (Entities, WithKey)
			when is_list (Entities), is_boolean (WithKey) ->
	try
		{ok, coerce_records_ok (enforce_ok_map (
				fun (Attachment) ->
					coerce_attachment (Attachment, WithKey)
				end,
				Entities))}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


coerce_annotation (Key, Value) ->
	try
		Entity = #ms_os_annotation_v1{
				key = enforce_ok_1 (coerce_identifier (Key)),
				value = enforce_ok_1 (coerce_annotation_value (Value))},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.

coerce_annotation_value (Value) ->
	coerce_value (Value).


coerce_annotation (Entity = #ms_os_annotation_v1{}) ->
	coerce_annotation (
			Entity#ms_os_annotation_v1.key,
			Entity#ms_os_annotation_v1.value);
	
coerce_annotation ({Key, Value}) ->
	coerce_annotation (Key, Value).


coerce_annotations (Entities)
			when is_list (Entities) ->
	try
		{ok, coerce_records_ok (enforce_ok_map (fun coerce_annotation/1, Entities))}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


coerce_identifier (Identifier)
			when is_binary (Identifier) ->
	{ok, Identifier};
	
coerce_identifier (Identifier)
			when is_atom (Identifier) ->
	coerce_identifier (erlang:atom_to_binary (Identifier, utf8)).

coerce_identifiers (Identifiers)
			when is_list (Identifiers) ->
	try
		{ok, enforce_ok_map (fun coerce_identifier/1, Identifiers)}
	catch throw : Error = {error, _} -> Error end.


coerce_content_type (ContentType)
			when is_binary (ContentType) ->
	{ok, ContentType};
	
coerce_content_type (ContentType) ->
	ve_cowboy:encode_content_type (ContentType).


coerce_fingerprint (Fingerprint)
			when is_binary (Fingerprint) ->
	{ok, Fingerprint}.


coerce_value (Value) ->
	{ok, Value}.

coerce_values (Values)
			when is_list (Values) ->
	{ok, Values}.


%----------------------------------------------------------------------------


coerce_records_ok (Records) ->
	lists:ukeysort (2, Records).

coerce_values_ok (Values) ->
	lists:usort (Values).


coerce_term (Term, Schema) ->
	case ve_generic_coders:validate_term (Term, Schema) of
		ok ->
			{ok, Term};
		Error = {error, _} ->
			Error
	end.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


coerce_object_patch (Patch) ->
	try
		{ok, coerce_object_patch_ok (Patch)}
	catch
		throw : {error, Reason} -> {error, Reason};
		throw : Reason -> {error, {invalid_object_patch, Patch, {unexpected_error, Reason, erlang:get_stacktrace ()}}};
		error : Reason -> {error, {invalid_object_patch, Patch, {unexpected_error, Reason, erlang:get_stacktrace ()}}};
		exit : Reason -> {error, {invalid_object_patch, Patch, {unexpected_error, Reason, erlang:get_stacktrace ()}}}
	end.


coerce_object_patch_ok (Patch = {data, exclude}) ->
	Patch;
	
coerce_object_patch_ok ({data, Operation, Data})
			when (Operation =:= update) ->
	{data, Operation, enforce_ok_1 (coerce_object_data (Data))};
	
	% ----------------------------------------
	
coerce_object_patch_ok (Patch = {indices_all, exclude}) ->
	Patch;
	
coerce_object_patch_ok ({indices_all, Operation, Indices})
			when (Operation =:= update) ->
	{indices_all, Operation, enforce_ok_1 (coerce_object_indices (Indices))};
	
coerce_object_patch_ok ({indices_each, Operation, Indices})
			when (Operation =:= update); (Operation =:= include) ->
	{indices_each, Operation, enforce_ok_1 (coerce_object_indices (Indices))};
	
coerce_object_patch_ok ({indices_each, Operation, Indices})
			when (Operation =:= exclude) ->
	{indices_each, Operation, enforce_ok_1 (coerce_identifiers (Indices))};
	
coerce_object_patch_ok ({index, Operation, Index})
			when (Operation =:= update); (Operation =:= include); (Operation =:= exclude) ->
	coerce_object_patch_ok ({indices_each, Operation, [Index]});
	
	% ----------------------------------------
	
coerce_object_patch_ok ({index_values, Operation, Index, Values})
			when (Operation =:= update); (Operation =:= include); (Operation =:= exclude) ->
	{index_values, Operation, enforce_ok_1 (coerce_identifier (Index)), enforce_ok_1 (coerce_object_index_values (Values))};
	
coerce_object_patch_ok ({index_value, Operation, Index, Value})
			when (Operation =:= include); (Operation =:= exclude) ->
	coerce_object_patch_ok ({index_values, Operation, Index, [Value]});
	
	% ----------------------------------------
	
coerce_object_patch_ok (Patch = {links_all, exclude}) ->
	Patch;
	
coerce_object_patch_ok ({links_all, Operation, Links})
			when (Operation =:= update) ->
	{links_all, Operation, enforce_ok_1 (coerce_object_links (Links))};
	
coerce_object_patch_ok ({links_each, Operation, Links})
			when (Operation =:= update); (Operation =:= include) ->
	{links_each, Operation, enforce_ok_1 (coerce_object_links (Links))};
	
coerce_object_patch_ok ({links_each, Operation, Links})
			when (Operation =:= exclude) ->
	{links_each, Operation, enforce_ok_1 (coerce_identifiers (Links))};
	
coerce_object_patch_ok ({link, Operation, Link})
			when (Operation =:= update); (Operation =:= include); (Operation =:= exclude) ->
	coerce_object_patch_ok ({links_each, Operation, [Link]});
	
	% ----------------------------------------
	
coerce_object_patch_ok ({link_references, Operation, Link, References})
			when (Operation =:= update); (Operation =:= include); (Operation =:= exclude) ->
	{link_references, Operation, enforce_ok_1 (coerce_identifier (Link)), enforce_ok_1 (coerce_object_link_references (References))};
	
coerce_object_patch_ok ({link_reference, Operation, Link, Reference})
			when (Operation =:= include); (Operation =:= exclude) ->
	coerce_object_patch_ok ({link_references, Operation, Link, [Reference]});
	
	% ----------------------------------------
	
coerce_object_patch_ok (Patch = {attachments_all, exclude}) ->
	Patch;
	
coerce_object_patch_ok ({attachments_all, Operation, Attachments})
			when (Operation =:= update) ->
	{attachments_all, Operation, enforce_ok_1 (coerce_object_attachments (Attachments))};
	
coerce_object_patch_ok ({attachments_each, Operation, Attachments})
			when (Operation =:= update); (Operation =:= include) ->
	{attachments_each, Operation, enforce_ok_1 (coerce_object_attachments (Attachments))};
	
coerce_object_patch_ok ({attachments_each, Operation, Attachments})
			when (Operation =:= exclude) ->
	{attachments_each, Operation, enforce_ok_1 (coerce_identifier (Attachments))};
	
coerce_object_patch_ok ({attachment, Operation, Attachment})
			when (Operation =:= update); (Operation =:= include); (Operation =:= exclude) ->
	coerce_object_patch_ok ({attachments_each, Operation, [Attachment]});
	
	% ----------------------------------------
	
coerce_object_patch_ok (Patch = {attachment_annotations_all, exclude}) ->
	Patch;
	
coerce_object_patch_ok ({attachment_annotations_all, Operation, Attachment, Annotations})
			when (Operation =:= update) ->
	{attachment_annotations_all, Operation, enforce_ok_1 (coerce_identifier (Attachment)), enforce_ok_1 (coerce_object_annotations (Annotations))};
	
coerce_object_patch_ok ({attachment_annotations_each, Operation, Attachment, Annotations})
			when (Operation =:= update); (Operation =:= include) ->
	{attachment_annotations_each, Operation, enforce_ok_1 (coerce_identifier (Attachment)), enforce_ok_1 (coerce_object_annotations (Annotations))};
	
coerce_object_patch_ok ({attachment_annotations_each, Operation, Attachment, Annotations})
			when (Operation =:= exclude) ->
	{attachment_annotations_each, Operation, enforce_ok_1 (coerce_identifier (Attachment)), enforce_ok_1 (coerce_identifier (Annotations))};
	
coerce_object_patch_ok ({attachment_annotation, Operation, Attachment, Annotation})
			when (Operation =:= update); (Operation =:= include); (Operation =:= exclude) ->
	coerce_object_patch_ok ({attachment_annotations_each, Operation, Attachment, [Annotation]});
	
	% ----------------------------------------
	
coerce_object_patch_ok (Patch = {annotations_all, exclude}) ->
	Patch;
	
coerce_object_patch_ok ({annotations_all, Operation, Annotations})
			when (Operation =:= update) ->
	{annotations_all, Operation, enforce_ok_1 (coerce_object_annotations (Annotations))};
	
coerce_object_patch_ok ({annotations_each, Operation, Annotations})
			when (Operation =:= update); (Operation =:= include) ->
	{annotations_each, Operation, enforce_ok_1 (coerce_object_annotations (Annotations))};
	
coerce_object_patch_ok ({annotations_each, Operation, Annotations})
			when (Operation =:= exclude) ->
	{annotations_each, Operation, enforce_ok_1 (coerce_identifiers (Annotations))};
	
coerce_object_patch_ok ({annotation, Operation, Annotation})
			when (Operation =:= update); (Operation =:= include); (Operation =:= exclude) ->
	coerce_object_patch_ok ({annotations_each, Operation, [Annotation]});
	
	% ----------------------------------------
	
coerce_object_patch_ok ({patches, Patches})
			when is_list (Patches) ->
	{patches, lists:map (fun coerce_object_patch_ok/1, Patches)}.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


coerce_object_selector (Selector) ->
	try
		{ok, coerce_object_selector_ok (Selector)}
	catch
		throw : {error, Reason} -> {error, Reason};
		throw : Reason -> {error, {invalid_object_selector, Selector, {unexpected_error, Reason, erlang:get_stacktrace ()}}};
		error : Reason -> {error, {invalid_object_selector, Selector, {unexpected_error, Reason, erlang:get_stacktrace ()}}};
		exit : Reason -> {error, {invalid_object_selector, Selector, {unexpected_error, Reason, erlang:get_stacktrace ()}}}
	end.


coerce_object_selector_ok (any) ->
	any;
	
coerce_object_selector_ok ({key, Key}) ->
	{key, enforce_ok_1 (coerce_object_key (Key))};
	
coerce_object_selector_ok ({collection, Collection}) ->
	{collection, enforce_ok_1 (coerce_identifier (Collection))};
	
coerce_object_selector_ok ({index, Index, {equals, Value}}) ->
	{index, enforce_ok_1 (coerce_identifier (Index)), {equals, enforce_ok_1 (coerce_object_index_value (Value))}};
	
coerce_object_selector_ok ({index, Index, {lesser, MaxValue}}) ->
	coerce_object_selector_ok ({index, Index, {lesser, MaxValue, true}});
	
coerce_object_selector_ok ({index, Index, {lesser, MaxValue, MaxValueInclusive}})
			when is_boolean (MaxValueInclusive) ->
	{index, enforce_ok_1 (coerce_identifier (Index)), {lesser, enforce_ok_1 (coerce_object_index_value (MaxValue)), MaxValueInclusive}};
	
coerce_object_selector_ok ({index, Index, {greater, MinValue}}) ->
	coerce_object_selector_ok ({index, Index, {greater, MinValue, true}});
	
coerce_object_selector_ok ({index, Index, {greater, MinValue, MinValueInclusive}})
			when is_boolean (MinValueInclusive) ->
	{index, enforce_ok_1 (coerce_identifier (Index)), {greater, enforce_ok_1 (coerce_object_index_value (MinValue)), MinValueInclusive}};
	
coerce_object_selector_ok ({index, Index, {range, MinValue, MaxValue}}) ->
	coerce_object_selector_ok ({index, Index, {range, MinValue, true, MaxValue, true}});
	
coerce_object_selector_ok ({index, Index, {range, MinValue, MinValueInclusive, MaxValue, MaxValueInclusive}})
			when is_boolean (MinValueInclusive), is_boolean (MaxValueInclusive) ->
	{index, enforce_ok_1 (coerce_identifier (Index)), {range, enforce_ok_1 (coerce_object_index_value (MinValue)), MinValueInclusive, enforce_ok_1 (coerce_object_index_value (MaxValue)), MaxValueInclusive}}.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


coerce_object_mangler (Mangler) ->
	try
		{ok, coerce_object_mangler_ok (Mangler)}
	catch
		throw : {error, Reason} -> {error, Reason};
		throw : Reason -> {error, {invalid_object_mangler, Mangler, {unexpected_error, Reason, erlang:get_stacktrace ()}}};
		error : Reason -> {error, {invalid_object_mangler, Mangler, {unexpected_error, Reason, erlang:get_stacktrace ()}}};
		exit : Reason -> {error, {invalid_object_mangler, Mangler, {unexpected_error, Reason, erlang:get_stacktrace ()}}}
	end.


coerce_object_mangler_ok (Mangler = object) ->
	Mangler;
	
coerce_object_mangler_ok (Mangler = key) ->
	Mangler;
	
coerce_object_mangler_ok (Mangler = {key, collection}) ->
	Mangler;
	
coerce_object_mangler_ok (Mangler = {key, object}) ->
	Mangler.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


validate_object (Term) ->
	validate_entity (Term, object).

validate_object (Term, WithKey) ->
	validate_entity (Term, {object, WithKey}).

validate_object_key (Term) ->
	validate_entity (Term, object_key).

validate_object_data (Term) ->
	validate_entity (Term, object_data).

validate_object_index (Term) ->
	validate_entity (Term, object_index).

validate_object_indices (Term) ->
	validate_entity (Term, object_indices).

validate_object_link (Term) ->
	validate_entity (Term, object_link).

validate_object_links (Term) ->
	validate_entity (Term, object_links).

validate_object_attachment (Term) ->
	validate_entity (Term, object_attachment).

validate_object_attachments (Term) ->
	validate_entity (Term, object_attachments).


validate_data (Term) ->
	validate_entity (Term, data).

validate_attachment (Term) ->
	validate_entity (Term, attachment).

validate_annotations (Term) ->
	validate_entity (Term, annotations).

validate_annotation (Term) ->
	validate_entity (Term, annotation).


validate_identifier (Term) ->
	validate_entity (Term, identifier).

validate_content_type (Term) ->
	validate_entity (Term, content_type).

validate_fingerprint (Term) ->
	validate_entity (Term, fingerprint).


validate_object_patch (Term) ->
	validate_entity (Term, object_patch).

validate_object_selector (Term) ->
	validate_entity (Term, object_selector).

validate_object_mangler (Term) ->
	validate_entity (Term, object_mangler).


validate_entity (Term, Type) ->
	ve_generic_coders:validate_term (Term, schema_term (Type)).


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


decode_json_object (Json) ->
	decode_json_entity (Json, object).

decode_json_object (Json, WithKey) ->
	decode_json_entity (Json, {object, WithKey}).

decode_json_objects (Json) ->
	decode_json_entity (Json, objects).


decode_json_object_key (Json) ->
	decode_json_entity (Json, object_key).

decode_json_object_data (Json) ->
	decode_json_entity (Json, object_data).

decode_json_object_indices (Json) ->
	decode_json_entity (Json, object_indices).

decode_json_object_index_values (Json) ->
	decode_json_entity (Json, object_index_values).

decode_json_object_index_value (Json) ->
	decode_json_entity (Json, object_index_value).

decode_json_object_links (Json) ->
	decode_json_entity (Json, object_links).

decode_json_object_link_references (Json) ->
	decode_json_entity (Json, object_link_references).

decode_json_object_link_reference (Json) ->
	decode_json_entity (Json, object_link_reference).

decode_json_object_attachments (Json) ->
	decode_json_entity (Json, object_attachments).

decode_json_object_attachment (Json) ->
	decode_json_entity (Json, object_attachment).

decode_json_object_annotations (Json) ->
	decode_json_entity (Json, object_annotations).

decode_json_object_annotation_value (Json) ->
	decode_json_entity (Json, object_annotation_value).


decode_json_data (Json) ->
	decode_json_entity (Json, data).

decode_json_attachment (Json) ->
	decode_json_entity (Json, attachment).

decode_json_annotations (Json) ->
	decode_json_entity (Json, annotations).

decode_json_annotation_value (Json) ->
	decode_json_entity (Json, annotation_value).


decode_json_identifier (Json) ->
	decode_json_entity (Json, identifier).

decode_json_identifiers (Json) ->
	decode_json_entity (Json, identifiers).

decode_json_content_type (Json) ->
	decode_json_entity (Json, content_type).

decode_json_fingerprint (Json) ->
	decode_json_entity (Json, fingerprint).


decode_json_entity (Json, Type) ->
	ve_json_coders:destructure_json (Json, schema_json (Type)).


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


encode_json_object (Object) ->
	encode_json_object (Object, true).


encode_json_object (Object = #ms_os_object_v1{}, WithKey)
			when is_boolean (WithKey) ->
	try
		Json = {struct, [
				{<<"key">>, if
							WithKey -> enforce_ok_1 (encode_json_object_key (Object#ms_os_object_v1.key));
							true -> null
						end},
				{<<"data">>, enforce_ok_1 (encode_json_object_data (Object#ms_os_object_v1.data))},
				{<<"indices">>, enforce_ok_1 (encode_json_object_indices (Object#ms_os_object_v1.indices))},
				{<<"links">>, enforce_ok_1 (encode_json_object_links (Object#ms_os_object_v1.links))},
				{<<"attachments">>, enforce_ok_1 (encode_json_object_attachments (Object#ms_os_object_v1.attachments))},
				{<<"annotations">>, enforce_ok_1 (encode_json_object_annotations (Object#ms_os_object_v1.annotations))}]},
		Json_2 = enforce_ok_1 (ve_json_coders:simplify_json (Json, {struct, exclude_null_attributes})),
		{ok, Json_2}
	catch throw : Error = {error, _} -> Error end.


encode_json_objects (Entities)
			when is_list (Entities) ->
	try
		{ok, enforce_ok_map (fun encode_json_object/1, Entities)}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


encode_json_object_key (none) ->
	{ok, null};
	
encode_json_object_key (Key = #ms_os_object_key_v1{}) ->
	try
		Json = {struct, [
				{<<"collection">>, enforce_ok_1 (encode_json_identifier (Key#ms_os_object_key_v1.collection))},
				{<<"object">>, enforce_ok_1 (encode_json_identifier (Key#ms_os_object_key_v1.object))}]},
		{ok, Json}
	catch throw : Error = {error, _} -> Error end;
	
encode_json_object_key (#ms_os_object_v1{key = Key}) ->
	encode_json_object_key (Key).


%----------------------------------------------------------------------------


encode_json_object_data (none) ->
	{ok, null};
	
encode_json_object_data (Data = #ms_os_data_v1{}) ->
	case encode_json_data (Data) of
		{ok, Json} ->
			ve_json_coders:simplify_json (Json, {struct, exclude_null_attributes});
		Error = {error, _} ->
			Error
	end;
	
encode_json_object_data (#ms_os_object_v1{data = Data}) ->
	encode_json_object_data (Data).


%----------------------------------------------------------------------------


encode_json_object_indices ([]) ->
	{ok, null};
	
encode_json_object_indices (none) ->
	{ok, null};
	
encode_json_object_indices (Indices)
			when is_list (Indices) ->
	try
		Json = {struct, lists:map (
				fun (#ms_os_object_index_v1{key = Index, values = Values}) ->
					{
							enforce_ok_1 (encode_json_identifier (Index)),
							enforce_ok_1 (encode_json_object_index_values (Values))}
				end,
				Indices)},
		{ok, Json}
	catch throw : Error = {error, _} -> Error end;
	
encode_json_object_indices (#ms_os_object_v1{indices = Indices}) ->
	encode_json_object_indices (Indices).


encode_json_object_index_values ([]) ->
	{ok, null};
	
encode_json_object_index_values (none) ->
	{ok, null};
	
encode_json_object_index_values (Values)
			when is_list (Values) ->
	try
		Json = enforce_ok_map (fun encode_json_object_index_value/1, Values),
		{ok, Json}
	catch throw : Error = {error, _} -> Error end;
	
encode_json_object_index_values (#ms_os_object_index_v1{values = Values}) ->
	encode_json_object_index_values (Values).


encode_json_object_index_value (Value) ->
	encode_json_value (Value).


%----------------------------------------------------------------------------


encode_json_object_links ([]) ->
	{ok, null};
	
encode_json_object_links (none) ->
	{ok, null};
	
encode_json_object_links (Links)
			when is_list (Links) ->
	try
		Json = {struct, lists:map (
				fun (#ms_os_object_link_v1{key = Link, references = References}) ->
					{
							enforce_ok_1 (encode_json_identifier (Link)),
							enforce_ok_1 (encode_json_object_link_references (References))}
				end,
				Links)},
		{ok, Json}
	catch throw : Error = {error, _} -> Error end;
	
encode_json_object_links (#ms_os_object_v1{links = Links}) ->
	encode_json_object_links (Links).


encode_json_object_link_references ([]) ->
	{ok, null};
	
encode_json_object_link_references (none) ->
	{ok, null};
	
encode_json_object_link_references (References)
			when is_list (References) ->
	try
		Json = enforce_ok_map (fun encode_json_object_link_reference/1, References),
		{ok, Json}
	catch throw : Error = {error, _} -> Error end;
	
encode_json_object_link_references (#ms_os_object_link_v1{references = References}) ->
	encode_json_object_link_references (References).


encode_json_object_link_reference (Reference) ->
	encode_json_object_key (Reference).


%----------------------------------------------------------------------------


encode_json_object_attachments ([]) ->
	{ok, null};
	
encode_json_object_attachments (none) ->
	{ok, null};
	
encode_json_object_attachments (Attachments)
			when is_list (Attachments) ->
	try
		Json = {struct, lists:map (
				fun ({Identifier, Attachment}) ->
					{
							enforce_ok_1 (encode_json_identifier (Identifier)),
							enforce_ok_1 (encode_json_object_attachment (Attachment))}
				end,
				Attachments)},
		{ok, Json}
	catch throw : Error = {error, _} -> Error end;
	
encode_json_object_attachments (#ms_os_object_v1{attachments = Attachments}) ->
	encode_json_object_attachments (Attachments).


encode_json_object_attachment (Attachment) ->
	case encode_json_attachment (Attachment) of
		{ok, Json} ->
			ve_json_coders:simplify_json (Json, {struct, exclude_null_attributes});
		Error = {error, _} ->
			Error
	end.


%----------------------------------------------------------------------------


encode_json_object_annotations ([]) ->
	{ok, null};
	
encode_json_object_annotations (none) ->
	{ok, null};
	
encode_json_object_annotations (Annotations)
			when is_list (Annotations) ->
	encode_json_annotations (Annotations);
	
encode_json_object_annotations (#ms_os_object_v1{annotations = Annotations}) ->
	encode_json_object_annotations (Annotations).


encode_json_object_annotation_value (Annotation) ->
	encode_json_annotation_value (Annotation).


%----------------------------------------------------------------------------


encode_json_data (Data = #ms_os_data_v1{}) ->
	try
		{TransferEncoding, Content} = enforce_ok_2 (encode_json_data_data (Data)),
		Json = {struct, [
				{<<"content-type">>, enforce_ok_1 (encode_json_content_type (Data#ms_os_data_v1.type))},
				{<<"content">>, Content},
				{<<"transfer-encoding">>, TransferEncoding}]},
		{ok, Json}
	catch throw : Error = {error, _} -> Error end.


encode_json_data_data (Data = #ms_os_data_v1{}) ->
	try
		ContentType = enforce_ok_1 (ve_cowboy:uncoerce_content_type (Data#ms_os_data_v1.type)),
		case ContentType of
			{json, utf8} ->
				{ok, <<"identity">>, Data#ms_os_data_v1.data};
			json ->
				{ok, <<"identity">>, Data#ms_os_data_v1.data};
			{text, utf8} ->
				{ok, <<"identity">>, enforce_ok_1 (ve_generic_coders:encode_string (Data#ms_os_data_v1.data))};
			text ->
				{ok, <<"identity">>, enforce_ok_1 (ve_generic_coders:encode_string (Data#ms_os_data_v1.data))};
			_ ->
				{BinaryContentType, BinaryContent} = enforce_ok_2 (encode_binary_data (ContentType, Data#ms_os_data_v1.data)),
				{ok, <<"hex">>, BinaryContentType, enforce_ok_1 (ve_generic_coders:encode_hex (BinaryContent))}
		end
	catch throw : Error = {error, _} -> Error end.


encode_binary_data (Data = #ms_os_data_v1{}) ->
	encode_binary_data (Data#ms_os_data_v1.type, Data#ms_os_data_v1.data).

encode_binary_data (ContentType, Content) ->
	case ve_cowboy:encode_content (ContentType, Content) of
		{ok, BinaryContentType, BinaryContent} ->
			{ok, BinaryContentType, BinaryContent};
		{error, {unsupported_content_type, _ContentType}} ->
			case ve_cowboy:coerce_content (ContentType, Content) of
				{ok, BinaryContent} ->
					{ok, ContentType, BinaryContent};
				Error = {error, _} ->
					Error
			end;
		Error = {error, _} ->
			Error
	end.


%----------------------------------------------------------------------------


encode_json_attachment (Attachment = #ms_os_attachment_v1{}) ->
	try
		Json = {struct, [
				{<<"content-type">>, enforce_ok_1 (encode_json_content_type (Attachment#ms_os_attachment_v1.type))},
				{<<"content-length">>, Attachment#ms_os_attachment_v1.size},
				{<<"fingerprint">>, enforce_ok_1 (encode_json_fingerprint (Attachment#ms_os_attachment_v1.fingerprint))},
				{<<"annotations">>, enforce_ok_1 (encode_json_annotations (Attachment#ms_os_attachment_v1.annotations))}]},
		Json_2 = enforce_ok_1 (ve_json_coders:simplify_json (Json, {struct, exclude_null_attributes})),
		{ok, Json_2}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


encode_json_annotations (Annotations)
			when is_list (Annotations) ->
	try
		Json = {struct, lists:map (
				fun (#ms_os_annotation_v1{key = Annotation, value = Value}) ->
					{
							enforce_ok_1 (encode_json_identifier (Annotation)),
							enforce_ok_1 (encode_json_annotation_value (Value))}
				end,
				Annotations)},
		Json_2 = enforce_ok_1 (ve_json_coders:simplify_json (Json, {struct, exclude_null_attributes})),
		{ok, Json}
	catch throw : Error = {error, _} -> Error end.


encode_json_annotation_value (#ms_os_annotation_v1{value = Value}) ->
	try
		Json = enforce_ok_1 (encode_json_annotation_value (Value)),
		{ok, Json}
	catch throw : Error = {error, _} -> Error end;
	
encode_json_annotation_value (Value) ->
	encode_json_value (Value).


%----------------------------------------------------------------------------


encode_json_identifier (Identifier)
			when is_binary (Identifier) ->
	{ok, Identifier}.

encode_json_identifiers (Identifiers)
			when is_list (Identifiers) ->
	try
		Json = enforce_ok_map (fun encode_json_identifier/1, Identifiers),
		{ok, Json}
	catch throw : Error = {error, _} -> Error end.


encode_json_content_type (ContentType)
			when is_binary (ContentType) ->
	{ok, ContentType}.


encode_json_fingerprint (Fingerprint)
			when is_binary (Fingerprint) ->
	{ok, Fingerprint}.


encode_json_value (Value) ->
	case ve_json_coders:validate_json (Value) of
		ok ->
			{ok, Value};
		Error = {error, _} ->
			Error
	end.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


schema_term ({object, WithKey})
			when is_boolean (WithKey) ->
	Record = #ms_os_object_v1{
			key = if
						WithKey -> {schema, fun schema_term/1, object_key};
						true -> {equals, none}
				end,
			data = {schema, fun schema_term/1, object_data},
			indices = {schema, fun schema_term/1, object_indices},
			links = {schema, fun schema_term/1, object_links},
			attachments = {schema, fun schema_term/1, object_attachments},
			annotations = {schema, fun schema_term/1, object_annotations}},
	{record, Record, invalid_object};
	
schema_term (object) ->
	schema_term ({object, true});
	
schema_term (object_key) ->
	Record = #ms_os_object_key_v1{
			collection = {schema, fun schema_term/1, identifier},
			object = {schema, fun schema_term/1, identifier}},
	{record, Record, invalid_object_key};
	
schema_term (object_data) ->
	{'orelse', [
				{equals, none},
				{schema, fun schema_term/1, data, invalid_object_data}],
			invalid_object_data};
	
schema_term (object_index) ->
	Record = #ms_os_object_index_v1{
			key = {schema, fun schema_term/1, identifier, invalid_object_index_key},
			values = {list, {schema, fun schema_term/1, value}, invalid_object_index_values}},
	{record, Record, invalid_object_index};
	
schema_term (object_indices) ->
	{list, {schema, fun schema_term/1, object_index}, invalid_object_indices};
	
schema_term (object_link) ->
	Record = #ms_os_object_link_v1{
			key = {schema, fun schema_term/1, identifier, invalid_object_link_key},
			references = {list, {schema, fun schema_term/1, object_key, invalid_object_link_reference}, invalid_object_link_references}},
	{record, Record, invalid_object_link};
	
schema_term (object_links) ->
	{list, {schema, fun schema_term/1, object_link}, invalid_object_links};
	
schema_term (object_attachment) ->
	{schema, fun schema_term/1, attachment, invalid_object_attachment};
	
schema_term (object_attachments) ->
	{list, {schema, fun schema_term/1, object_attachment}, invalid_object_attachments};
	
schema_term (object_annotation) ->
	{schema, fun schema_term/1, annotation, invalid_object_annotation};
	
schema_term (object_annotations) ->
	{schema, fun schema_term/1, annotations, invalid_object_annotations};
	
schema_term (data) ->
	Record = #ms_os_data_v1{
			type = {schema, fun schema_term/1, content_type, invalid_data_type},
			data = {schema, fun schema_term/1, value, invalid_data_data}},
	{record, Record, invalid_data};
	
schema_term (attachments) ->
	{list, {schema, fun schema_term/1, attachments}, invalid_attachments};
	
schema_term ({attachment, WithKey})
			when is_boolean (WithKey) ->
	Record = #ms_os_attachment_v1{
			key = if
						WithKey -> {schema, fun schema_term/1, identifier, invalid_attachment_key};
						true -> {equals, none}
				end,
			type = {schema, fun schema_term/1, content_type, invalid_attachment_type},
			size = {integer, {positive, false}, invalid_attachment_size},
			fingerprint = {schema, fun schema_term/1, fingerprint, invalid_attachment_fingerprint},
			annotations = {schema, fun schema_term/1, annotations, invalid_attachment_annotations}},
	{record, Record, invalid_attachment};
	
schema_term (attachment) ->
	schema_term ({attachment, true});
	
schema_term (annotations) ->
	{list, {schema, fun schema_term/1, annotation}, invalid_annotations};
	
schema_term (annotation) ->
	Record = #ms_os_annotation_v1{
			key = {schema, fun schema_term/1, identifier, invalid_annotation_key},
			value = {schema, fun schema_term/1, value, invalid_annotation_value}},
	{record, Record, invalid_annotation};
	
schema_term (identifier) ->
	{binary, invalid_identifier};
	
schema_term (content_type) ->
	{binary, invalid_content_type};
	
schema_term (fingerprint) ->
	{binary, invalid_fingerprint};
	
schema_term (value) ->
	{simple_term};
	
schema_term (object_patch) ->
	% FIXME: Implement this!
	{term};
	
schema_term (object_selector) ->
	% FIXME: Implement this!
	{term};
	
schema_term (object_mangler) ->
	% FIXME: Implement this!
	{term}.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


-spec schema_json (
		{object, boolean()} | object | objects
			| object_key | object_data
			| object_indices | object_index_values | object_index_value
			| object_links | object_link_references | object_link_reference
			| object_attachments | object_attachment
			| object_annotations | object_annotation_value
			| data | {data, none} | {data, identity} | {data, hex}
			| {attachment, boolean()} | attachment | annotations | annotation_value
			| identifier | identifiers | content_type | fingerprint | value
) -> ve_json_coders:destructure_json_schema().


schema_json ({object, WithKey})
			when is_boolean (WithKey) ->
	Record = #ms_os_object_v1{
			key = if
						WithKey -> {<<"key">>, {schema, fun schema_json/1, object_key}};
						true -> none
					end,
			data = {<<"data">>, {schema, fun schema_json/1, object_data}, none},
			indices = {<<"indices">>, {schema, fun schema_json/1, object_indices}, []},
			links = {<<"links">>, {schema, fun schema_json/1, object_links}, []},
			attachments = {<<"attachments">>, {schema, fun schema_json/1, object_attachments}, []},
			annotations = {<<"annotations">>, {schema, fun schema_json/1, object_annotations}, []}},
	{object, attributes, Record, false};
	
schema_json (object) ->
	schema_json ({object, true});
	
schema_json (objects) ->
	{list, {schema, fun schema_json/1, {object, true}}};
	
schema_json (object_key) ->
	Record = #ms_os_object_key_v1{
			collection = {<<"collection">>, {schema, fun schema_json/1, identifier}},
			object = {<<"object">>, {schema, fun schema_json/1, identifier}}},
	{object, attributes, Record, false};
	
schema_json (object_data) ->
	{'orelse', [
			{equals, null, none},
			{schema, fun schema_json/1, data}]};
	
schema_json (object_indices) ->
	{'orelse', [
			{equals, null, []},
			{object, attributes_map, {record, ms_os_object_index_v1},
					{schema, fun schema_json/1, identifier},
					{schema, fun schema_json/1, object_index_values}}]};
	
schema_json (object_index_values) ->
	{'orelse', [
			{equals, null, []},
			{list, {schema, fun schema_json/1, object_index_value}}]};
	
schema_json (object_index_value) ->
	schema_json (value);
	
schema_json (object_links) ->
	{'orelse', [
			{equals, null, []},
			{object, attributes_map, {record, ms_os_object_link_v1},
					{schema, fun schema_json/1, identifier},
					{schema, fun schema_json/1, object_link_references}}]};
	
schema_json (object_link_references) ->
	{'orelse', [
			{equals, null, []},
			{list, {schema, fun schema_json/1, object_link_reference}}]};
	
schema_json (object_link_reference) ->
	{'orelse', [
			{equals, null, none},
			{schema, fun schema_json/1, object_key}]};
	
schema_json (object_attachments) ->
	{'orelse', [
			{equals, null, []},
			{compose, [
					{object, attributes_map, tuple,
							{schema, fun schema_json/1, identifier},
							{schema, fun schema_json/1, object_attachment}},
					{transform,
							fun ({Key, Attachment}) ->
								Attachment#ms_os_attachment_v1{key = Key}
							end}]}]};
	
schema_json (object_attachment) ->
	{'orelse', [
			{equals, null, none},
			{schema, fun schema_json/1, {attachment, false}}]};
	
schema_json (object_annotations) ->
	{'orelse', [
			{equals, null, []},
			{schema, fun schema_json/1, annotations}]};
	
schema_json (object_annotation_value) ->
	schema_json (annotation_value);
	
schema_json (data) ->
	{'orelse', [
			{schema, fun schema_json/1, {data, none}},
			{schema, fun schema_json/1, {data, identity}},
			{schema, fun schema_json/1, {data, hex}}]};
	
schema_json ({data, none}) ->
	Record = #ms_os_data_v1{
			type = {<<"content-type">>, {schema, fun schema_json/1, content_type}},
			data = {<<"content">>, {schema, fun schema_json/1, value}}},
	{object, attributes, Record, false};
	
schema_json ({data, identity}) ->
	Transformer = fun (Json) ->
			case ve_json_coders:destructure_json (Json, {object, attribute, <<"transfer-encoding">>, {string}}) of
				{ok, <<"identity">>} ->
					Record = #ms_os_data_v1{
							type = {<<"content-type">>, {schema, fun schema_json/1, content_type}},
							data = {<<"content">>, {json}}},
					% FIXME: Check for other extra attributes!
					ve_json_coders:destructure_json (Json, {object, attributes, Record, true});
				{ok, Encoding} ->
					{error, {unexpected_transfer_encoding, Encoding}};
				Error = {error, _} ->
					ve_transcript:trace_error ("a", [{r, Error}]),
					Error
			end
		end,
	{transform_ok, Transformer};
	
schema_json ({data, hex}) ->
	Transformer = fun (Json) ->
			case ve_json_coders:destructure_json (Json, {object, attribute, <<"transfer-encoding">>, {string}}) of
				{ok, <<"hex">>} ->
					{error, {unsupported_transfer_encoding, <<"hex">>}};
				{ok, Encoding} ->
					{error, {unexpected_transfer_encoding, Encoding}};
				Error = {error, _} ->
					Error
			end
		end,
	{transform_ok, Transformer};
	
schema_json ({attachment, WithKey})
			when is_boolean (WithKey) ->
	Record = #ms_os_attachment_v1{
			key = if
						WithKey -> {<<"key">>, {schema, fun schema_json/1, identifier}};
						true -> none
					end,
			type = {<<"content-type">>, {schema, fun schema_json/1, content_type}},
			size = {<<"content-length">>, {integer}},
			fingerprint = {<<"fingerprint">>, {schema, fun schema_json/1, fingerprint}},
			annotations = {<<"annotations">>, {'orelse', [{equals, null, []}, {schema, fun schema_json/1, annotations}]}, []}},
	{object, attributes, Record, false};
	
schema_json (attachment) ->
	schema_json ({attachment, true});
	
schema_json (annotations) ->
	{object, attributes_map, {record, ms_os_annotation_v1},
			{schema, fun schema_json/1, identifier},
			{schema, fun schema_json/1, annotation_value}};
	
schema_json (annotation_value) ->
	schema_json (value);
	
schema_json (identifier) ->
	{string};
	
schema_json (content_type) ->
	{string};
	
schema_json (fingerprint) ->
	{string};
	
schema_json (value) ->
	{json}.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------
