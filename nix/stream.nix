_ukanren: {
  mplus =
    s1: s2:
    if s1 == null then
      s2
    else
      {
        inherit (s1) head;
        tail = _ukanren.mplus s2 s1.tail;
      };

  bind =
    stream: g:
    if stream == null then null else _ukanren.mplus (g stream.head) (_ukanren.bind stream.tail g);

  streamTake =
    n: stream:
    if n == 0 || stream == null then
      [ ]
    else
      [ stream.head ] ++ _ukanren.streamTake (n - 1) stream.tail;
}
