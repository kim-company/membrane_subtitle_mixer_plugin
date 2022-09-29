module FLV.Tag.Native

interface([NIF])

spec add_caption(flv :: payload, text :: string) :: {:ok :: label, payload} | {:error :: label, atom()}
spec clear_caption(flv :: payload) :: {:ok :: label, payload} | {:error :: label, atom()}
