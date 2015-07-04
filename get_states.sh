#!/bin/sh

for f in state-machines/*.sm; do
  prog=`echo $f | awk -F/ '{print $2}' | awk -F. '{print $1}'`

  if [ -f states/$prog/.states ]; then

    for line in `cat states/$prog/.states`; do
      echo states/$prog/$line.png
    done

  fi
done
