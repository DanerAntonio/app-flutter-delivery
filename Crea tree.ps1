param([string]$Path = "lib")

function Show-Tree {
  param([string]$p, [string]$prefix = "")
  $items = Get-ChildItem -LiteralPath $p | Sort-Object { -not $_.PSIsContainer }, Name
  for ($i=0; $i -lt $items.Count; $i++) {
    $last = ($i -eq $items.Count - 1)
    $item = $items[$i]
    $branch = $last ? "└── " : "├── "
    Write-Output "$prefix$branch$($item.Name)"
    if ($item.PSIsContainer) {
      $newPrefix = $prefix + ($last ? "    " : "│   ")
      Show-Tree -p $item.FullName -prefix $newPrefix
    }
  }
}

"lib/" | Out-File lib_tree.txt -Encoding utf8
Show-Tree -p $Path | Out-File lib_tree.txt -Append -Encoding utf8
