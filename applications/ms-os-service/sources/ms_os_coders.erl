%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


-module (ms_os_coders).


-export ([
		merge_object/2,
		patch_object/2,
		match_object/2,
		mangle_object/2]).

-export ([
		coerce_object/6, coerce_object/1, coerce_object/2,
		coerce_object_key/2, coerce_object_key/1,
		coerce_object_data/2, coerce_object_data/1,
		coerce_object_index/2, coerce_object_index/1, coerce_object_indices/1,
		coerce_object_link/2, coerce_object_link/1, coerce_object_links/1,
		coerce_object_attachment/5, coerce_object_attachment/1, coerce_object_attachments/1,
		coerce_data/2, coerce_data/1,
		coerce_attachment/4, coerce_attachment/1,
		coerce_annotation/2, coerce_annotation/1, coerce_annotations/1,
		coerce_identifier/1,
		coerce_content_type/1,
		coerce_fingerprint/1,
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
		decode_json_object/1, decode_json_object/2,
		decode_json_object_key/1,
		decode_json_object_data/1,
		decode_json_object_indices/1,
		decode_json_object_links/1,
		decode_json_object_attachments/1,
		decode_json_data/1,
		decode_json_attachment/1,
		decode_json_annotations/1,
		decode_json_identifier/1,
		decode_json_content_type/1,
		decode_json_fingerprint/1]).

-export ([
		encode_json_object/1, encode_json_object/2,
		encode_json_object_key/1,
		encode_json_object_data/1,
		encode_json_object_indices/1, encode_json_object_index/1,
		encode_json_object_links/1, encode_json_object_link/1,
		encode_json_object_attachments/1, encode_json_object_attachment/1,
		encode_json_data/1,
		encode_json_attachment/1,
		encode_json_annotations/1, encode_json_annotation/1,
		encode_json_identifier/1,
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


merge_object (Object, none) ->
	{ok, Object};
	
merge_object (NewObject, _OldObject) ->
	{ok, NewObject}.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


patch_object ({data, update, Data}, Object) ->
	{ok, Object#ms_os_object_v1{data = Data}};
	
patch_object ({indices, update, Indices}, Object) ->
	{ok, Object#ms_os_object_v1{indices = Indices}};
	
patch_object ({links, update, Links}, Object) ->
	{ok, Object#ms_os_object_v1{links = Links}};
	
patch_object ({attachments, update, Attachments}, Object) ->
	{ok, Object#ms_os_object_v1{attachments = Attachments}};
	
patch_object ({annotations, update, Annotations}, Object) ->
	{ok, Object#ms_os_object_v1{annotations = Annotations}};
	
patch_object (Patch, _Object) ->
	{error, {invalid_object_patch, Patch}}.


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
	try
		Entity = #ms_os_object_v1{
				key = enforce_ok_1 (coerce_object_key (Key)),
				data = case Data of
						none ->
							none;
						_ ->
							enforce_ok_1 (coerce_object_data (Data))
				end,
				indices = enforce_ok_1 (coerce_object_indices (Indices)),
				links = enforce_ok_1 (coerce_object_links (Links)),
				attachments = enforce_ok_1 (coerce_object_attachments (Attachments)),
				annotations = enforce_ok_1 (coerce_annotations (Annotations))},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.


coerce_object (Entity = #ms_os_object_v1{}) ->
	coerce_object (
			Entity#ms_os_object_v1.key,
			Entity#ms_os_object_v1.data,
			Entity#ms_os_object_v1.indices,
			Entity#ms_os_object_v1.links,
			Entity#ms_os_object_v1.attachments,
			Entity#ms_os_object_v1.annotations);
	
coerce_object ({Key, Data, Indices, Links, Attachments, Annotations}) ->
	coerce_object (Key, Data, Indices, Links, Attachments, Annotations).


coerce_object (Key = #ms_os_object_key_v1{}, Object = #ms_os_object_v1{key = none}) ->
	coerce_object (Object#ms_os_object_v1{key = Key}).


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


%----------------------------------------------------------------------------


coerce_object_data (Type, Data) ->
	coerce_data (Type, Data).


coerce_object_data (none) ->
	{ok, none};
	
coerce_object_data (Data) ->
	coerce_data (Data).


%----------------------------------------------------------------------------


coerce_object_index (Index, Values) ->
	try
		Entity = #ms_os_object_index_v1{
				index = enforce_ok_1 (coerce_identifier (Index)),
				values = enforce_ok_map (fun coerce_object_index_value/1, Values)},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.

coerce_object_index_value (Value) ->
	coerce_term (Value, {simple_term}).


coerce_object_index (Entity = #ms_os_object_index_v1{}) ->
	coerce_object_index (
			Entity#ms_os_object_index_v1.index,
			Entity#ms_os_object_index_v1.values);
	
coerce_object_index ({Index, Values}) ->
	coerce_object_index (Index, Values).


coerce_object_indices (none) ->
	{ok, []};
	
coerce_object_indices (Indices)
			when is_list (Indices) ->
	try
		{ok, enforce_ok_map (fun coerce_object_index/1, Indices)}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


coerce_object_link (Link, References) ->
	try
		Entity = #ms_os_object_link_v1{
				link = enforce_ok_1 (coerce_identifier (Link)),
				references = enforce_ok_map (fun coerce_object_key/1, References)},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.


coerce_object_link (Entity = #ms_os_object_link_v1{}) ->
	coerce_object_link (
			Entity#ms_os_object_link_v1.link,
			Entity#ms_os_object_link_v1.references);
	
coerce_object_link ({Link, References}) ->
	coerce_object_link (Link, References).


coerce_object_links (none) ->
	{ok, []};
	
coerce_object_links (Links)
			when is_list (Links) ->
	try
		{ok, enforce_ok_map (fun coerce_object_link/1, Links)}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


coerce_object_attachment (Identifier, Type, Size, Fingerprint, Annotations) ->
	try
		Entity = {
				enforce_ok_1 (coerce_identifier (Identifier)),
				enforce_ok_1 (coerce_attachment (Type, Size, Fingerprint, Annotations))},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.


coerce_object_attachment ({Identifier, Attachment}) ->
	try
		Entity = {
				enforce_ok_1 (coerce_identifier (Identifier)),
				enforce_ok_1 (coerce_attachment (Attachment))},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end;
	
coerce_object_attachment ({Identifier, Type, Size, Fingerprint, Annotations}) ->
	coerce_object_attachment (Identifier, Type, Size, Fingerprint, Annotations).


coerce_object_attachments (none) ->
	{ok, []};
	
coerce_object_attachments (Attachments)
			when is_list (Attachments) ->
	try
		{ok, enforce_ok_map (fun coerce_object_attachment/1, Attachments)}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


coerce_data (Type, Data) ->
	try
		Entity = #ms_os_data_v1{
				type = enforce_ok_1 (coerce_content_type (Type)),
				data = enforce_ok_1 (coerce_data_data (Data))},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.

coerce_data_data (Data) ->
	coerce_term (Data, {simple_term}).


coerce_data (Entity = #ms_os_data_v1{}) ->
	coerce_data (
			Entity#ms_os_data_v1.type,
			Entity#ms_os_data_v1.data);
	
coerce_data ({Type, Data}) ->
	coerce_data (Type, Data).


%----------------------------------------------------------------------------


coerce_attachment (Type, Size, Fingerprint, Annotations) ->
	try
		Entity = #ms_os_attachment_v1{
				type = enforce_ok_1 (coerce_content_type (Type)),
				size = enforce_ok_1 (coerce_term (Size, {integer, {positive, false}})),
				fingerprint = enforce_ok_1 (coerce_fingerprint (Fingerprint)),
				annotations = enforce_ok_1 (coerce_annotations (Annotations))},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.


coerce_attachment (Entity = #ms_os_attachment_v1{}) ->
	coerce_attachment (
			Entity#ms_os_attachment_v1.type,
			Entity#ms_os_attachment_v1.size,
			Entity#ms_os_attachment_v1.fingerprint,
			Entity#ms_os_attachment_v1.annotations);
	
coerce_attachment ({Type, Size, Fingerprint, Annotations}) ->
	coerce_attachment (Type, Size, Fingerprint, Annotations).


%----------------------------------------------------------------------------


coerce_annotation (Identifier, Value) ->
	try
		Entity = #ms_os_annotation_v1{
				annotation = enforce_ok_1 (coerce_identifier (Identifier)),
				value = enforce_ok_1 (coerce_annotation_value (Value))},
		{ok, Entity}
	catch throw : Error = {error, _} -> Error end.

coerce_annotation_value (Value) ->
	coerce_term (Value, {simple_term}).


coerce_annotation (Entity = #ms_os_annotation_v1{}) ->
	coerce_annotation (
			Entity#ms_os_annotation_v1.annotation,
			Entity#ms_os_annotation_v1.value);
	
coerce_annotation ({Annotation, Value}) ->
	coerce_annotation (Annotation, Value).


coerce_annotations (none) ->
	{ok, []};
	
coerce_annotations (Annotations)
			when is_list (Annotations) ->
	try
		{ok, enforce_ok_map (fun coerce_annotation/1, Annotations)}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


coerce_identifier (Identifier)
			when is_binary (Identifier) ->
	{ok, Identifier};
	
coerce_identifier (Identifier)
			when is_atom (Identifier) ->
	coerce_identifier (erlang:atom_to_binary (Identifier, utf8)).


coerce_content_type (ContentType)
			when is_binary (ContentType) ->
	{ok, ContentType};
	
coerce_content_type (ContentType) ->
	ve_cowboy:encode_content_type (ContentType).


coerce_fingerprint (Fingerprint)
			when is_binary (Fingerprint) ->
	{ok, Fingerprint}.



%----------------------------------------------------------------------------


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


coerce_object_patch_ok ({data, Operation, Data})
			when (Operation =:= update) ->
	{data, Operation, enforce_ok_1 (coerce_object_data (Data))};
	
coerce_object_patch_ok ({indices, Operation, Indices})
			when (Operation =:= update); (Operation =:= include), (Operation =:= exclude) ->
	{indices, Operation, enforce_ok_1 (coerce_object_indices (Indices))};
	
coerce_object_patch_ok ({links, Operation, Links})
			when (Operation =:= update); (Operation =:= include), (Operation =:= exclude) ->
	{links, Operation, enforce_ok_1 (coerce_object_links (Links))};
	
coerce_object_patch_ok ({attachments, Operation, Attachments})
			when (Operation =:= update); (Operation =:= include), (Operation =:= exclude) ->
	{attachments, Operation, enforce_ok_1 (coerce_object_attachments (Attachments))};
	
coerce_object_patch_ok ({annotations, Operation, Annotations})
			when (Operation =:= update); (Operation =:= include), (Operation =:= exclude) ->
	{annotations, Operation, enforce_ok_1 (coerce_annotations (Annotations))}.


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
	{index, enforce_ok_1 (coerce_identifier (Index)), {equals, Value}};
	
coerce_object_selector_ok ({index, Index, {lesser, MaxValue}}) ->
	coerce_object_selector_ok ({index, Index, {lesser, MaxValue, true}});
	
coerce_object_selector_ok ({index, Index, {lesser, MaxValue, MaxValueInclusive}}) ->
	{index, enforce_ok_1 (coerce_identifier (Index)), {lesser, MaxValue, MaxValueInclusive}};
	
coerce_object_selector_ok ({index, Index, {greater, MinValue}}) ->
	coerce_object_selector_ok ({index, Index, {greater, MinValue, true}});
	
coerce_object_selector_ok ({index, Index, {greater, MinValue, MinValueInclusive}}) ->
	{index, enforce_ok_1 (coerce_identifier (Index)), {greater, MinValue, MinValueInclusive}};
	
coerce_object_selector_ok ({index, Index, {range, MinValue, MaxValue}}) ->
	coerce_object_selector_ok ({index, Index, {range, MinValue, true, MaxValue, true}});
	
coerce_object_selector_ok ({index, Index, {range, MinValue, MinValueInclusive, MaxValue, MaxValueInclusive}})
			when is_boolean (MinValueInclusive), is_boolean (MaxValueInclusive) ->
	{index, enforce_ok_1 (coerce_identifier (Index)), {range, MinValue, MinValueInclusive, MaxValue, MaxValueInclusive}}.


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

decode_json_object_key (Json) ->
	decode_json_entity (Json, object_key).

decode_json_object_data (Json) ->
	decode_json_entity (Json, object_data).

decode_json_object_indices (Json) ->
	decode_json_entity (Json, object_indices).

decode_json_object_links (Json) ->
	decode_json_entity (Json, object_links).

decode_json_object_attachments (Json) ->
	decode_json_entity (Json, object_attachments).


decode_json_data (Json) ->
	decode_json_entity (Json, data).

decode_json_attachment (Json) ->
	decode_json_entity (Json, attachment).

decode_json_annotations (Json) ->
	decode_json_entity (Json, annotations).


decode_json_identifier (Json) ->
	decode_json_entity (Json, identifier).

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


encode_json_object (Object = #ms_os_object_v1{}, _WithKey) ->
	try
		Json = {struct, [
				{<<"key">>, enforce_ok_1 (encode_json_object_key (Object#ms_os_object_v1.key))},
				{<<"data">>, enforce_ok_1 (encode_json_object_data (Object#ms_os_object_v1.data))},
				{<<"indices">>, enforce_ok_1 (encode_json_object_indices (Object#ms_os_object_v1.indices))},
				{<<"links">>, enforce_ok_1 (encode_json_object_links (Object#ms_os_object_v1.links))},
				{<<"attachments">>, enforce_ok_1 (encode_json_object_attachments (Object#ms_os_object_v1.attachments))},
				{<<"annotations">>, enforce_ok_1 (encode_json_annotations (Object#ms_os_object_v1.annotations))}]},
		{ok, Json}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


encode_json_object_key (Key = #ms_os_object_key_v1{}) ->
	try
		Json = {struct, [
				{<<"collection">>, enforce_ok_1 (encode_json_identifier (Key#ms_os_object_key_v1.collection))},
				{<<"object">>, enforce_ok_1 (encode_json_identifier (Key#ms_os_object_key_v1.object))}]},
		{ok, Json}
	catch throw : Error = {error, _} -> Error end;
	
encode_json_object_key (none) ->
	{ok, null}.


%----------------------------------------------------------------------------


encode_json_object_data (Data = #ms_os_data_v1{}) ->
	encode_json_data (Data);
	
encode_json_object_data (none) ->
	{ok, null}.


%----------------------------------------------------------------------------


encode_json_object_indices (Indices)
			when is_list (Indices) ->
	try
		Json = {struct, lists:map (
				fun (#ms_os_object_index_v1{index = Index, values = Values}) ->
					{
							enforce_ok_1 (encode_json_identifier (Index)),
							enforce_ok_map (fun encode_json_object_index_value/1, Values)}
				end,
				Indices)},
		{ok, Json}
	catch throw : Error = {error, _} -> Error end.


encode_json_object_index (#ms_os_object_index_v1{values = Values}) ->
	try
		Json = enforce_ok_map (fun encode_json_object_index_value/1, Values),
		{ok, Json}
	catch throw : Error = {error, _} -> Error end.


encode_json_object_index_value (Value) ->
	{ok, Value}.


%----------------------------------------------------------------------------


encode_json_object_links (Links)
			when is_list (Links) ->
	try
		Json = {struct, lists:map (
				fun (#ms_os_object_link_v1{link = Link, references = References}) ->
					{
							enforce_ok_1 (encode_json_identifier (Link)),
							enforce_ok_map (fun encode_json_object_key/1, References)}
				end,
				Links)},
		{ok, Json}
	catch throw : Error = {error, _} -> Error end.


encode_json_object_link (#ms_os_object_link_v1{references = References}) ->
	try
		Json = enforce_ok_map (fun encode_json_object_key/1, References),
		{ok, Json}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


encode_json_object_attachments (Attachments)
			when is_list (Attachments) ->
	try
		Json = {struct, lists:map (
				fun ({Identifier, Attachment}) ->
					{
							enforce_ok_1 (encode_json_identifier (Identifier)),
							enforce_ok_1 (encode_json_attachment (Attachment))}
				end,
				Attachments)},
		{ok, Json}
	catch throw : Error = {error, _} -> Error end.


encode_json_object_attachment (Attachment) ->
	encode_json_attachment (Attachment).


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
		{ok, Json}
	catch throw : Error = {error, _} -> Error end.


%----------------------------------------------------------------------------


encode_json_annotations (Annotations)
			when is_list (Annotations) ->
	try
		Json = {struct, lists:map (
				fun (#ms_os_annotation_v1{annotation = Annotation, value = Value}) ->
					{
							enforce_ok_1 (encode_json_identifier (Annotation)),
							enforce_ok_1 (encode_json_annotation_value (Value))}
				end,
				Annotations)},
		{ok, Json}
	catch throw : Error = {error, _} -> Error end.


encode_json_annotation (#ms_os_annotation_v1{value = Value}) ->
	try
		Json = enforce_ok_1 (encode_json_annotation_value (Value)),
		{ok, Json}
	catch throw : Error = {error, _} -> Error end.


encode_json_annotation_value (Value) ->
	{ok, Value}.


%----------------------------------------------------------------------------


encode_json_identifier (Identifier)
			when is_binary (Identifier) ->
	{ok, Identifier}.


encode_json_content_type (ContentType)
			when is_binary (ContentType) ->
	{ok, ContentType}.


encode_json_fingerprint (Fingerprint)
			when is_binary (Fingerprint) ->
	{ok, Fingerprint}.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


schema_term ({object, WithKey})
			when is_boolean (WithKey) ->
	Record = #ms_os_object_v1{
			key = if
					WithKey -> {schema, fun schema_term/1, object_key};
					true -> {equals, none}
			end,
			data = {'orelse', [{equals, none}, {schema, fun schema_term/1, object_data}], invalid_object_data},
			indices = {schema, fun schema_term/1, object_indices},
			links = {schema, fun schema_term/1, object_links},
			attachments = {schema, fun schema_term/1, object_attachments},
			annotations = {schema, fun schema_term/1, annotations, invalid_object_annotations}},
	{record, Record, invalid_object};
	
schema_term (object_with_key) ->
	schema_term ({object, true});
	
schema_term (object_without_key) ->
	schema_term ({object, false});
	
schema_term (object) ->
	schema_term ({object, true});
	
schema_term (object_key) ->
	Record = #ms_os_object_key_v1{
			collection = {schema, fun schema_term/1, identifier},
			object = {schema, fun schema_term/1, identifier}},
	{record, Record, invalid_object_key};
	
schema_term (object_data) ->
	{schema, fun schema_term/1, data, invalid_object_data};
	
schema_term (object_index) ->
	Record = #ms_os_object_index_v1{
			index = {schema, fun schema_term/1, identifier, invalid_object_index_identifier},
			values = {list, {simple_term}, invalid_object_index_values}},
	{record, Record, invalid_object_index};
	
schema_term (object_indices) ->
	{list, {schema, fun schema_term/1, object_index}, invalid_object_indices};
	
schema_term (object_link) ->
	Record = #ms_os_object_link_v1{
			link = {schema, fun schema_term/1, identifier, invalid_object_link_identifier},
			references = {list, {schema, fun schema_term/1, object_key, invalid_object_link_reference}, invalid_object_link_references}},
	{record, Record, invalid_object_link};
	
schema_term (object_links) ->
	{list, {schema, fun schema_term/1, object_link}, invalid_object_links};
	
schema_term (object_attachment) ->
	Tuple = {
			{schema, fun schema_term/1, identifier, invalid_object_attachment_identifier},
			{schema, fun schema_term/1, attachment, invalid_object_attachment_attachment}},
	{tuple, Tuple, invalid_object_attachment};
	
schema_term (object_attachments) ->
	{list, {schema, fun schema_term/1, object_attachment}, invalid_object_attachments};
	
schema_term (data) ->
	Record = #ms_os_data_v1{
			type = {schema, fun schema_term/1, content_type, invalid_data_type},
			data = {simple_term, invalid_data_data}},
	{record, Record, invalid_data};
	
schema_term (attachment) ->
	Record = #ms_os_attachment_v1{
			type = {schema, fun schema_term/1, content_type, invalid_attachment_type},
			size = {integer, {positive, false}, invalid_attachment_size},
			fingerprint = {schema, fun schema_term/1, fingerprint, invalid_attachment_fingerprint},
			annotations = {schema, fun schema_term/1, annotations, invalid_attachment_annotations}},
	{record, Record, invalid_attachment};
	
schema_term (annotations) ->
	{list, {schema, fun schema_term/1, annotation}, invalid_annotations};
	
schema_term (annotation) ->
	Record = #ms_os_annotation_v1{
			annotation = {schema, fun schema_term/1, identifier, invalid_annotation_identifier},
			value = {simple_term, invalid_annotation_value}},
	{record, Record, invalid_annotation};
	
schema_term (identifier) ->
	{binary, invalid_identifier};
	
schema_term (content_type) ->
	{binary, invalid_content_type};
	
schema_term (fingerprint) ->
	{binary, invalid_fingerprint};
	
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
		{object, boolean()} | object_with_key | object_without_key | object
				| object_key | object_data | object_indices | object_links | object_attachments
				| data | attachment | annotations | identifier | content_type | fingerprint)
	-> ve_json_coders:destructure_json_schema().


schema_json ({object, WithKey}) ->
	Record = #ms_os_object_v1{
			key = if WithKey -> {<<"key">>, {schema, fun schema_json/1, object_key}}; true -> none end,
			data = {<<"data">>, {'orelse', [{equals, null, none}, {schema, fun schema_json/1, object_data}]}, none},
			indices = {<<"indices">>, {'orelse', [{equals, null, []}, {schema, fun schema_json/1, object_indices}]}, []},
			links = {<<"links">>, {'orelse', [{equals, null, []}, {schema, fun schema_json/1, object_links}]}, []},
			attachments = {<<"attachments">>, {'orelse', [{equals, null, []}, {schema, fun schema_json/1, object_attachments}]}, []},
			annotations = {<<"annotations">>, {'orelse', [{equals, null, []}, {schema, fun schema_json/1, annotations}]}, []}},
	{object, attributes, Record, false};
	
schema_json (object_with_key) ->
	schema_json ({object, true});
	
schema_json (object_without_key) ->
	schema_json ({object, false});
	
schema_json (object) ->
	schema_json ({object, true});
	
schema_json (object_key) ->
	Record = #ms_os_object_key_v1{
			collection = {<<"collection">>, {schema, fun schema_json/1, identifier}},
			object = {<<"object">>, {schema, fun schema_json/1, identifier}}},
	{object, attributes, Record, false};
	
schema_json (object_data) ->
	schema_json (data);
	
schema_json (object_indices) ->
	{object, attributes_map, {record, ms_os_object_index_v1}, {schema, fun schema_json/1, identifier},
			{'orelse', [{equals, null, []}, {list, {json}}]}};
	
schema_json (object_links) ->
	{object, attributes_map, {record, ms_os_object_link_v1}, {schema, fun schema_json/1, identifier},
			{'orelse', [{equals, null, []}, {list, {schema, fun schema_json/1, object_key}}]}};
	
schema_json (object_attachments) ->
	{object, attributes_map, tuple, {schema, fun schema_json/1, identifier},
			{'orelse', [{equals, null, none}, {schema, fun schema_json/1, attachment}]}};
	
schema_json (data) ->
	{'orelse', [
			{schema, fun schema_json/1, {data, none}},
			{schema, fun schema_json/1, {data, identity}},
			{schema, fun schema_json/1, {data, base64}}]};
	
schema_json ({data, none}) ->
	Record = #ms_os_data_v1{
			type = {<<"content-type">>, {schema, fun schema_json/1, content_type}},
			data = {<<"content">>, {json}}},
	{object, attributes, Record, false};
	
schema_json ({data, identity}) ->
	{transform_ok,
			fun (Json) ->
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
			end};
	
schema_json ({data, base64}) ->
	{transform_ok,
			fun (Json) ->
				case ve_json_coders:destructure_json (Json, {object, attribute, <<"transfer-encoding">>, {string}}) of
					{ok, <<"hex">>} ->
						{error, {unsupported_transfer_encoding, <<"hex">>}};
					{ok, Encoding} ->
						{error, {unexpected_transfer_encoding, Encoding}};
					Error = {error, _} ->
						Error
				end
			end};
	
schema_json (attachment) ->
	Record = #ms_os_attachment_v1{
			type = {<<"content-type">>, {schema, fun schema_json/1, content_type}},
			size = {<<"content-length">>, {integer}},
			fingerprint = {<<"fingerprint">>, {schema, fun schema_json/1, fingerprint}},
			annotations = {<<"annotations">>, {'orelse', [{equals, null, []}, {schema, fun schema_json/1, annotations}]}, []}},
	{object, attributes, Record, false};
	
schema_json (annotations) ->
	{object, attributes_map, {record, ms_os_annotation_v1}, {schema, fun schema_json/1, identifier}, {json}};
	
schema_json (identifier) ->
	{string};
	
schema_json (content_type) ->
	{string};
	
schema_json (fingerprint) ->
	{string}.


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------
