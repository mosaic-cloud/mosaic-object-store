%----------------------------------------------------------------------------
%----------------------------------------------------------------------------


-record (ms_os_object_v1, {
		key :: ms_os_object_key() | none | any(),
		data :: ms_os_data() | none | any(),
		indices :: list(ms_os_object_index()) | any(),
		links :: list(ms_os_object_link()) | any(),
		attachments :: list(ms_os_attachment()) | any(),
		annotations :: list(ms_os_annotation()) | any()}).

-record (ms_os_object_key_v1, {
		collection :: ms_os_identifier() | any(),
		object :: ms_os_identifier() | any()}).

-record (ms_os_object_index_v1, {
		key :: ms_os_identifier() | any(),
		values :: list(ms_os_value()) | any()}).

-record (ms_os_object_link_v1, {
		key :: ms_os_identifier() | any(),
		references :: list(ms_os_object_key()) | any()}).


-record (ms_os_data_v1, {
		type :: ms_os_content_type() | any(),
		data :: any()}).

-record (ms_os_attachment_v1, {
		key :: ms_os_identifier() | any(),
		type :: ms_os_content_type() | any(),
		size :: pos_integer() | any(),
		fingerprint :: ms_os_fingerprint() | any(),
		annotations :: list(ms_os_annotation()) | any()}).

-record (ms_os_annotation_v1, {
		key :: ms_os_identifier() | any(),
		value :: ms_os_value() | any()}).


%----------------------------------------------------------------------------


-type ms_os_object() :: #ms_os_object_v1{}.
-type ms_os_object_key() :: #ms_os_object_key_v1{}.
-type ms_os_object_index() :: #ms_os_object_index_v1{}.
-type ms_os_object_link() :: #ms_os_object_link_v1{}.

-type ms_os_data() :: #ms_os_data_v1{}.
-type ms_os_attachment() :: #ms_os_attachment_v1{}.
-type ms_os_annotation() :: #ms_os_annotation_v1{}.

-type ms_os_identifier() :: binary().
-type ms_os_value() :: any().
-type ms_os_content_type() :: binary().
-type ms_os_fingerprint() :: binary().


%----------------------------------------------------------------------------
%----------------------------------------------------------------------------
