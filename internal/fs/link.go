package fs

import (
	"context"
	"strings"

	"github.com/OpenListTeam/OpenList/v4/internal/model"
	"github.com/OpenListTeam/OpenList/v4/internal/op"
	"github.com/OpenListTeam/OpenList/v4/server/common"
	"github.com/pkg/errors"
)

func link(ctx context.Context, path string, args model.LinkArgs) (*model.Link, model.Obj, error) {
	storage, actualPath, err := op.GetStorageAndActualPath(path)
	if err != nil {
		return nil, nil, errors.WithMessage(err, "存储获取失败")
	}
	l, obj, err := op.Link(ctx, storage, actualPath, args)
	if err != nil {
		return nil, nil, errors.WithMessage(err, "链接失败")
	}
	if l.URL != "" && !strings.HasPrefix(l.URL, "http://") && !strings.HasPrefix(l.URL, "https://") {
		l.URL = common.GetApiUrl(ctx) + l.URL
	}
	return l, obj, nil
}
