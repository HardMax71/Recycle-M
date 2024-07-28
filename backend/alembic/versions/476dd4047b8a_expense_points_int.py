"""expense points int

Revision ID: 476dd4047b8a
Revises: 4d804be61d26
Create Date: 2024-07-26 13:58:55.317992

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '476dd4047b8a'
down_revision: Union[str, None] = '4d804be61d26'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('expenses', sa.Column('points', sa.Integer(), nullable=True))
    op.drop_column('expenses', 'amount')
    # ### end Alembic commands ###


def downgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('expenses', sa.Column('amount', sa.FLOAT(), nullable=True))
    op.drop_column('expenses', 'points')
    # ### end Alembic commands ###