[.[] | select(.requestId != null)] |
group_by(.requestId) | map(last) as $deduped |

def calc_cost:
  .message.usage as $u | .message.model as $m |
  (if ($m // "" | test("opus")) then
    (($u.input_tokens // 0) * 15 + ($u.output_tokens // 0) * 75 + ($u.cache_creation_input_tokens // 0) * 18.75 + ($u.cache_read_input_tokens // 0) * 1.5) / 1000000
  elif ($m // "" | test("haiku")) then
    (($u.input_tokens // 0) * 0.25 + ($u.output_tokens // 0) * 1.25 + ($u.cache_creation_input_tokens // 0) * 0.3 + ($u.cache_read_input_tokens // 0) * 0.03) / 1000000
  else
    (($u.input_tokens // 0) * 3 + ($u.output_tokens // 0) * 15 + ($u.cache_creation_input_tokens // 0) * 3.75 + ($u.cache_read_input_tokens // 0) * 0.3) / 1000000
  end);

($deduped | map(select(.timestamp > $ENV.TODAY_START)) | map(calc_cost) | add // 0) as $today_cost |
($deduped | map(select(.timestamp > $ENV.FIVE_H_AGO))) as $block_entries |
($block_entries | map(calc_cost) | add // 0) as $block_cost |
($block_entries | map(.timestamp) | sort | first // null) as $block_earliest |

{
  today_cost: ($today_cost * 100 | round / 100),
  block_cost: ($block_cost * 100 | round / 100),
  block_earliest: $block_earliest
}
